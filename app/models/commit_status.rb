# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class CommitStatus < Ci::ApplicationRecord
  include EachBatch
  include Ci::Partitionable
  include Ci::HasStatus
  include Ci::HasCommitBuildStatus
  include TokenAuthenticatable
  include AfterCommitQueue
  include BulkInsertableAssociations
  include TaggableQueries
  include EnumInheritance

  self.table_name = :ci_builds

  def self.find_sti_class(type_name)
    require_dependency 'ci/processable'
    require_dependency 'ci/build'
    require_dependency 'ci/bridge'
    super
  end

  def self.inheritance_column = 'type'

  def self.inheritance_column_to_class_map
    {
      ci_build: 'Ci::Build',
      ci_bridge: 'Ci::Bridge',
      generic_commit_status: 'GenericCommitStatus'
    }.freeze
  end

  belongs_to :project, inverse_of: :builds
  belongs_to :pipeline,
    class_name: 'Ci::Pipeline',
    foreign_key: :commit_id,
    inverse_of: :statuses
  belongs_to :user
  belongs_to :runner, optional: true
  belongs_to :ci_stage,
    class_name: 'Ci::Stage',
    foreign_key: :stage_id
  has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build
  has_many :taggings, class_name: 'Ci::BuildTag',
    foreign_key: :build_id,
    inverse_of: :build
  has_many :needs, class_name: 'Ci::BuildNeed', foreign_key: :build_id, inverse_of: :build

  has_many :tags,
    class_name: 'Ci::Tag',
    through: :taggings,
    source: :tag
  belongs_to :ci_stage,
    class_name: 'Ci::Stage',
    foreign_key: :stage_id

  attribute :retried, default: false
  alias_method :author, :user
  alias_attribute :pipeline_id, :commit_id

  enum :scheduling_type, { stage: 0, dag: 1 }, prefix: true
  enum :failure_reason, Enums::Ci::CommitStatus.failure_reasons
  enum :status, Ci::HasStatus::STATUSES_ENUM

  enum :type, {
    ci_build: 0,
    ci_bridge: 1,
    generic_commit_status: 2,
  }

  delegate :commit, to: :pipeline
  delegate :sha, :short_sha, :before_sha, to: :pipeline

  validates :pipeline, presence: true, unless: :importing?
  validates :name, presence: true, unless: :importing?
  validates :ci_stage, presence: true, on: :create, unless: :importing?
  validates :ref, :target_url, :description, length: { maximum: 255 }
  validates :project, presence: true

  before_save if: :status_changed?, unless: :importing? do
    # we mark `processed` as always changed:
    # another process might change its value and our object
    # will not be refreshed to pick the change
    processed_will_change!

    if latest?
      self.processed = false # force refresh of all dependent ones
    elsif retried?
      self.processed = true # retried are considered to be already processed
    end
  end

  scope :latest, -> { where(retried: [false, nil]) }
  scope :retried, -> { where(retried: true) }
  scope :ordered_by_stage, -> { order(stage_idx: :asc) }
  scope :after_stage, ->(index) { where('stage_idx > ?', index) }
  scope :scoped_pipeline, -> do
    where(arel_table[:commit_id].eq(Ci::Pipeline.arel_table[:id]))
  end

  scope :with_project_preload, -> do
    preload(project: :namespace)
  end

  scope :match_id_and_lock_version, ->(items) do
    # it expects that items are an array of attributes to match
    # each hash needs to have `id` and `lock_version`
    or_conditions = items.inject(none) do |relation, item|
      match = CommitStatus.default_scoped.where(item.slice(:id, :lock_version))

      relation.or(match)
    end

    merge(or_conditions)
  end

  scope :in_pipelines, ->(pipelines) { where(pipeline: pipelines) }
  scope :before_stage, ->(index) { where('stage_idx < ?', index) }
  scope :updated_at_before, ->(date) { where("#{quoted_table_name}.updated_at < ?", date) }
  scope :created_at_before, ->(date) { where("#{quoted_table_name}.created_at < ?", date) }
  scope :scheduled_at_before, ->(date) {
    where("#{quoted_table_name}.scheduled_at IS NOT NULL AND #{quoted_table_name}.scheduled_at < ?", date)
  }

  def self.update_as_processed!
    # Marks items as processed
    # we do not increase `lock_version`, as we are the one
    # holding given lock_version (Optimisitc Locking)
    update_all(processed: true)
  end

  def importing?
    false
  end

  def latest?
    !retried?
  end

  def all_met_to_become_pending?
    true
  end

  def supports_force_cancel?
    false
  end

  def stage_name
    ci_stage&.name
  end

  # Time spent running.
  def duration
    calculate_duration(started_at, finished_at)
  end

  def cancelable?
    false
  end

  def force_cancelable?
    false
  end

  # TODO: Temporary technical debt so we can ignore `stage`: https://gitlab.com/gitlab-org/gitlab/-/issues/507579
  alias_method :stage, :stage_name

  def update_older_statuses_retried!
    pipeline
      .statuses
      .latest
      .where(name: name)
      .where.not(id: id)
      .update_all(retried: true, processed: true)
  end
end
