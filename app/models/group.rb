# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Group < ApplicationRecord
  include Routable
  include Groups::Destroyable
  include Gitlab::VisibilityLevel

  belongs_to :namespace, autosave: true, class_name: 'Namespaces::GroupNamespace',
    foreign_key: 'namespace_id', inverse_of: :group
  accepts_nested_attributes_for :namespace
  has_one :route, through: :namespace
  has_many :members, -> { non_request.non_minimal_access }, through: :namespace
  has_many :users, through: :members
  has_many :notification_settings, as: :source, dependent: :delete_all

  attribute :namespace_parent_id

  with_options to: :namespace do
    delegate :find_by_full_path
    delegate :has_parent?
    delegate :visibility_level
    delegate :creator_id
  end

  before_validation :ensure_namespace
  after_create :add_creator_as_owner
  validates :name,
    format: {
      with: Gitlab::Regex.group_name_regex,
      message: Gitlab::Regex.group_name_regex_message
    },
    if: :name_changed?

  after_update :sync_namespace if :name_changed? || :path_changed?

  def self_and_ancestors_asc
    namespace.self_and_ancestors(hierarchy_order: :asc).map(&:group).compact
  end

  def to_param
    namespace.full_path
  end

  def visibility_level_field
    :visibility_level
  end

  def visibility_level_value
    visibility_level
  end

  def default_branch_name
    'main'
  end

  def root_ancestor
    namespace.root_ancestor.group
  end

  private

  def ensure_namespace
    self.namespace ||= Namespaces::GroupNamespace.new(creator_id: creator_id)
    self.namespace.name ||= name
    self.namespace.path ||= path
    self.namespace.parent_id = namespace_parent_id if namespace_parent_id.present?
  end

  def sync_namespace
    namespace.update!(name: name, path: path)
  end

  def add_creator_as_owner
    GroupMember.create!(
      user: namespace.owner,
      access_level: Gitlab::Access::OWNER,
      namespace: namespace
    )
  end
end
