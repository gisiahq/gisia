# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class User < ApplicationRecord
  extend Gitlab::ConfigHelper

  include CaseSensitivity
  include FromUnion
  include Gitlab::ConfigHelper
  include HasUserType
  include Users::Authenticatable
  include Users::HasState
  include Users::CiTokenAuthenticatable
  include Users::Authorizable
  include Users::HasUploads

  FEED_TOKEN_PREFIX = 'glft-'

  def self.reference_prefix
    '@'
  end

  # Pattern used to extract `@username` user references from text
  def self.reference_pattern
    @reference_pattern ||=
      %r{
        (?<!\w)
        #{Regexp.escape(reference_prefix)}
        (?<username>#{Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
      }x
  end

  has_many :notification_settings, dependent: :destroy
  has_many :keys
  has_many :personal_access_tokens, dependent: :destroy
  has_many :project_members, -> { where(requested_at: nil) }
  has_many :projects, -> { distinct }, through: :project_members
  has_many :group_members, -> {
    where(requested_at: nil).where('access_level >= ?', Gitlab::Access::GUEST)
  }, class_name: 'GroupMember'
  has_many :groups, through: :group_members
  has_many :namespace_pins, class_name: 'Namespaces::Pin', dependent: :destroy, inverse_of: :user
  has_many :merge_request_assignees, dependent: :destroy, inverse_of: :assignee
  has_many :assigned_merge_requests, through: :merge_request_assignees, source: :merge_request
  has_many :merge_request_reviewers, inverse_of: :reviewer
  has_many :reviews, foreign_key: :author_id, inverse_of: :author
  has_many :work_item_assignees, inverse_of: :assignee, dependent: :destroy
  has_many :assigned_work_items, class_name: 'WorkItem', through: :work_item_assignees, source: :work_item
  # Todo, redirect to anonymouse
  # has_many :notes, foreign_key: :author_id, dependent: :destroy
  has_one :namespace, class_name: 'Namespaces::UserNamespace',
    required: true,
    dependent: :destroy,
    foreign_key: :creator_id,
    inverse_of: :creator,
    autosave: true

  before_validation :set_default_name
  before_validation :ensure_namespace, on: :create

  validates :username,
    presence: true,
    exclusion: { in: Gitlab::PathRegex::TOP_LEVEL_ROUTES, message: 'is a reserved name' }
  validates :namespace, presence: true
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_nil: true
  validates :preferred_language, inclusion: { in: Gitlab::I18n.available_locales }, allow_nil: true

  attribute :preferred_language, default: 'en'


  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :admins, -> { where(admin: true) }
  scope :active, -> { with_state(:active).non_internal }
  scope :blocked_pending_approval, -> { with_state(:blocked_pending_approval) }
  scope :by_user_email, ->(emails) { iwhere(email: Array(emails)) }
  scope :by_username, ->(usernames) { iwhere(username: Array(usernames).map(&:to_s)) }
  scope :by_login, ->(login) do
    return none if login.blank?

    stripped_login = login.strip
    login.include?('@') ? iwhere(email: stripped_login) : iwhere(username: stripped_login)
  end

  class << self
    def find_by_login(login)
      by_login(login).take
    end

    def find_by_ssh_key_id(key_id)
      find_by('EXISTS (?)', Key.select(1).where('keys.user_id = users.id').auth.regular_keys.where(id: key_id))
    end

    def ransackable_attributes(_auth_object = nil)
      %w[name username]
    end

    def ransackable_associations(_auth_object = nil)
      %w[assigned_merge_requests merge_request_assignees merge_request_reviewers reviews]
    end

    # Find a User by their primary email or any associated confirmed secondary email
    def find_by_any_email(email, confirmed: false)
      return unless email

      by_any_email(email, confirmed: confirmed).take
    end

    def by_any_email(emails, confirmed: false)
      return none if Array(emails).all?(&:nil?)

      from_users = by_user_email(emails)
      from_users = from_users.confirmed if confirmed

      from_users
    end

  end

  def can?(action, subject = :global, **)
    Ability.allowed?(self, action, subject, **)
  end

  def active_for_authentication?
    super && can?(:log_in)
  end

  def inactive_message
    blocked? ? :blocked : super
  end

  def requires_ldap_check?
    false
  end

  def try_obtain_ldap_lease
    false
  end

  def has_composite_identity?
    false
  end

  def ci_job_token_scope_cache_key
    "users:#{id}:ci:job_token_scope"
  end

  def set_ci_job_token_scope!(job)
    Gitlab::SafeRequestStore[ci_job_token_scope_cache_key] = Ci::JobToken::Scope.new(job.project)
  end

  def required_terms_not_accepted?
    false
  end

  def can_admin_all_resources?
    can?(:admin_all_resources)
  end

  def can_admin_organization?(_organization)
    can_admin_all_resources?
  end

  def notification_email_or_default
    email
  end

  def notification_email_for(_group = nil)
    notification_email_or_default
  end

  def notification_settings_for(source)
    return unless source

    notification_settings.find_by(source: source)
  end

  DEFAULT_NOTIFICATION_LEVEL = :participating

  def global_notification_setting
    setting = notification_settings.find_or_initialize_by(source_type: nil, source_id: nil)
    setting.update(level: DEFAULT_NOTIFICATION_LEVEL) unless setting.persisted?
    setting
  end

  def closest_non_global_group_notification_setting(_group)
    nil
  end

  def notified_of_own_activity?
    false
  end

  # Todo, same as the foss
  def can_trigger_notifications?
    true
  end

  def to_reference(_from = nil, target_container: nil, full: nil)
    "#{self.class.reference_prefix}#{username}"
  end

  def public_email
    email
  end

  def commit_email_or_default
    return private_commit_email if self.commit_email == Gitlab::PrivateCommitEmail::TOKEN

    # The commit email is the same as the primary email if undefined
    self.commit_email.presence || self.email
  end

  # Todo, setup commit_email
  def commit_email
  end


  def self.available_for_membership_in(ns)
    active.where.not(id: ns.members.select(:user_id))
  end

  def authorized_groups
    project_parent_ns = Namespace.where(id: project_members.select(:namespace_id)).select(:parent_id)

    Group
      .where(namespace_id: group_members.select(:namespace_id))
      .or(Group.where(namespace_id: project_parent_ns))
  end

  def authorized_for_namespace?(ns)
    return ns.creator_id == id if ns.is_a?(Namespaces::UserNamespace)

    Member.non_request.where(namespace_id: ns.traversal_ids, user_id: id).exists?
  end

  def max_member_access_for_namespace(ns)
    GroupMember.non_request
      .where(namespace_id: ns.traversal_ids, user_id: id)
      .maximum(:access_level) || Gitlab::Access::NO_ACCESS
  end

  def member_of_namespace_tree?(ns)
    memberships = Member.non_request.where(user_id: id)

    memberships.where(namespace_id: ns.traversal_ids).exists? ||
      memberships.joins(:namespace)
                 .where('namespaces.traversal_ids @> ARRAY[?]::bigint[]', ns.id)
                 .exists?
  end

  def authorized_projects
    Project.joins(:namespace).where(authorized_namespace_condition)
  end

  def visible_projects_in_namespace(ns)
    all_projects = ns.descendant_projects
    return all_projects if authorized_for_namespace?(ns)

    ns.public_descendant_projects
      .or(all_projects.joins(:namespace).where(authorized_namespace_condition))
  end

  def maintained_group_namespaces
    Namespaces::GroupNamespace.where(
      ApplicationRecord.sanitize_sql_array(
        ['namespaces.traversal_ids && ARRAY(SELECT namespace_id FROM members WHERE user_id = :user_id AND requested_at IS NULL AND access_level >= :maintainer)::bigint[]',
          { user_id: id, maintainer: Gitlab::Access::MAINTAINER }]
      )
    )
  end

  def namespaces_for_project_creation
    own_namespace = Namespace.where(id: namespace.id)
    return own_namespace.or(Namespace.where(type: Group.sti_name)) if admin?

    own_namespace.or(Namespace.where(id: maintained_group_namespaces.select(:id)))
  end

  def namespaces_for_group_creation
    return Namespaces::GroupNamespace.all if admin?

    maintained_group_namespaces
  end

  def organization_id
    Organizations::Organization::DEFAULT_ORGANIZATION_ID
  end

  def organization
    Organizations::Organization.default_organization
  end

  def member_of_organization?(*args)
    true
  end

  # Todo,
  def private_rofile?
    false
  end

  private

  def authorized_namespace_condition
    ApplicationRecord.sanitize_sql_array(
      ['namespaces.traversal_ids && ARRAY(SELECT namespace_id FROM members WHERE user_id = :user_id AND requested_at IS NULL AND access_level > :minimal)::bigint[]',
        { user_id: id, minimal: Gitlab::Access::MINIMAL_ACCESS }]
    )
  end

  def set_default_name
    self.name = username if name.nil?
  end

  def ensure_namespace
    ns = namespace || build_namespace(owner: self)
    ns.path = username
    ns.name = name
  end
end

