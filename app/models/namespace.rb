# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Namespace < ApplicationRecord
  include Routable
  include HasPlan
  include BulkUsersByEmailLoad
  include BulkMemberAccessLoad
  include Gitlab::VisibilityLevel
  include Gitlab::Utils::StrongMemoize
  include Namespaces::Traversal::Recursive
  include Namespaces::Traversal::Linear
  include Namespaces::Traversal::Cached
  include Namespaces::Traversal::Traversable
  include Namespaces::HasReference

  URL_MAX_LENGTH = 255
  NUMBER_OF_ANCESTORS_ALLOWED = 20

  belongs_to :parent, class_name: 'Namespace', optional: true
  has_many :children, class_name: 'Namespaces::GroupNamespace', foreign_key: :parent_id
  has_many :all_children, class_name: 'Namespace', foreign_key: :parent_id

  belongs_to :creator, class_name: 'User', inverse_of: :namespace
  belongs_to :owner, class_name: 'User', foreign_key: :creator_id, optional: true
  has_one :project, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :pending_builds, class_name: 'Ci::PendingBuild'
  has_many :protected_refs, foreign_key: :namespace_id, inverse_of: :namespace, dependent: :destroy
  has_many :protected_branches, class_name: 'ProtectedBranch', foreign_key: :namespace_id, inverse_of: :namespace,
    dependent: :destroy
  has_many :protected_tags, class_name: 'ProtectedTag', foreign_key: :namespace_id, inverse_of: :namespace,
    dependent: :destroy

  has_one :namespace_route, foreign_key: :namespace_id, autosave: false, inverse_of: :namespace, class_name: 'Route'
  has_one :route, foreign_key: :namespace_id, autosave: true, inverse_of: :namespace, class_name: 'Route',
    dependent: :destroy
  has_one :namespace_settings, foreign_key: :namespace_id, inverse_of: :namespace, autosave: true,
    dependent: :destroy, class_name: 'NamespaceSetting'
  has_many :labels, foreign_key: :namespace_id, inverse_of: :namespace, dependent: :destroy
  has_many :web_hooks, class_name: 'WebHook', foreign_key: :namespace_id, inverse_of: :namespace, dependent: :destroy
  has_one :board, foreign_key: :namespace_id, inverse_of: :namespace, dependent: :destroy

  before_validation :prepare_route
  after_validation :set_path_errors

  validates :route, presence: true
  validates :creator, presence: true
  validates :name, uniqueness: { scope: :parent_id, case_sensitive: false }, on: :create
  validates :path,
    presence: true,
    length: { maximum: URL_MAX_LENGTH }
  validates :path,
    format: { with: Gitlab::Regex.oci_repository_path_regex, message: Gitlab::Regex.oci_repository_path_regex_message },
    if: :path_changed?
  validate :path_not_reserved, if: -> { parent_id.nil? && path_changed? }

  delegate :name, to: :creator, allow_nil: false, prefix: true

  scope :with_route, lambda {
    includes(:route).allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421843')
  }
  scope :user_and_group_only, -> { where(type: %w[User Group]) }
  scope :without_project_namespaces, -> { where.not(type: Namespaces::ProjectNamespace.sti_name) }
  scope :search, ->(query) { where('LOWER(name) LIKE :q OR LOWER(path) LIKE :q', q: "%#{query.downcase}%") }
  scope :by_parent, ->(parent) { where(parent_id: parent) }
  scope :top_level, -> { by_parent(nil) }

  class << self
    def find_by_id_or_path(id)
      if id.to_s.match?(/\A\d+\z/)
        find_by(id: id)
      else
        joins(:route).find_by(routes: { path: id.to_s.downcase })
      end
    end

    def sti_class_for(type_name)
      case type_name
      when Namespaces::GroupNamespace.sti_name
        Namespaces::GroupNamespace
      when Namespaces::ProjectNamespace.sti_name
        Namespaces::ProjectNamespace
      when Namespaces::UserNamespace.sti_name
        Namespaces::UserNamespace
      else
        Namespace
      end
    end

    def find_top_level
      top_level.take
    end
  end

  def organization_id
    Organizations::Organization::DEFAULT_ORGANIZATION_ID
  end

  def organization
    Organizations::Organization.default_organization
  end

  def visibility_level_field
    :visibility_level
  end

  def root?
    !has_parent?
  end

  def has_parent?
    parent_id.present? || parent.present?
  end

  def enabled_git_access_protocol; end

  def human_name
    path
  end

  def name_with_type
    "#{type} - #{full_name}"
  end

  def resource
    case self
    when Namespaces::ProjectNamespace
      project
    when Namespaces::GroupNamespace
      group
    else
      self
    end
  end

  def init_member
    creator = User.find_by_id(creator_id)
    team.add_owner(creator)
  end

  def pipeline_variables_default_role
    # Todo,
    ProjectCiCdSetting::NO_ONE_ALLOWED_ROLE
  end

  def user_namespace?
    type == Namespaces::UserNamespace.sti_name
  end

  def group_namespace?
    type == Group.sti_name
  end

  def descendant_projects
    nps = self_and_descendant_ids(skope: Namespaces::ProjectNamespace).id_not_in(id)

    Project.where(namespace: nps)
  end

  def descendant_groups
    nps = self_and_descendant_ids(skope: Namespaces::GroupNamespace).id_not_in(id)

    Group.where(namespace: nps)
  end

  def self_or_ancestors_archived?
    false
  end

  def project_namespace?
    type == Namespaces::ProjectNamespace.sti_name
  end

  def full_path
    route&.path || path
  end

  def kind
    return 'group' if group_namespace?
    return 'project' if project_namespace?

    'user'
  end

  private

  def path_not_reserved
    errors.add(:path, 'is a reserved name') if Gitlab::PathRegex::TOP_LEVEL_ROUTES.include?(path.to_s.downcase)
  end
end
