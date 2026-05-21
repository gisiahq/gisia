# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

class LfsObjectsProject < ApplicationRecord
  include ::EachBatch

  belongs_to :project
  belongs_to :lfs_object

  before_validation :ensure_uniqueness

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id, :repository_type], message: "already exists in repository" }
  validates :project_id, presence: true

  after_validation :update_oid

  after_commit :update_project_statistics, on: [:create, :destroy]

  enum :repository_type, { project: 0, wiki: 1, design: 2 }

  scope :project_repository_type, -> { project }
  scope :project_id_in, ->(ids) { where(project_id: ids) }
  scope :lfs_object_in, ->(lfs_objects) { where(lfs_object: lfs_objects) }

  def self.link_to_project!(lfs_object, project, repository_type)
    safe_find_or_create_by!(lfs_object_id: lfs_object.id, project_id: project.id, repository_type: repository_type) # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- We can't use an upsert here because there is no uniqueness constraint: https://gitlab.com/gitlab-org/gitlab/-/issues/347466
  end

  def self.update_statistics_for_project_id(project_id)
    # todo: implement project cache worker for lfs_objects_size stats
  end

  private

  def update_oid
    return unless respond_to?(:oid) && lfs_object

    self.oid = lfs_object.oid if oid != lfs_object.oid
  end

  def ensure_uniqueness
    return if project_id.nil? || lfs_object_id.nil?

    lock_key = [project_id, lfs_object_id, repository_type.presence || 'null'].join('-')

    lock_expression = "hashtext(#{connection.quote(lock_key)})"

    connection.execute("SELECT pg_advisory_xact_lock(#{lock_expression})")
  end

  def update_project_statistics
    self.class.update_statistics_for_project_id(project_id)
  end
end
