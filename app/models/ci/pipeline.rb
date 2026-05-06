# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Ci
  class Pipeline < Ci::ApplicationRecord
    include Ci::Buildable
    include Ci::HasStatus
    include Ci::HasCompletionReason
    include AfterCommitQueue

    include AtomicInternalId
    include Ci::HasRef
    include Ci::HasCommit
    include Ci::HasMergeRequest
    include UpdatedAtFilterable
    include FromUnion
    include Ci::Pipelines::Processable
    include Ci::Pipelines::HasPersistentRef
    include Ci::Pipelines::HasVariables

    attr_accessor :config_metadata, :partition_id

    DEFAULT_CONFIG_PATH = '.gitlab-ci.yml'
    COUNT_FAILED_JOBS_LIMIT = 101
    INPUTS_LIMIT = 20

    paginates_per 15

    enum :source, Enums::Ci::Pipeline.sources
    enum :config_source, Enums::Ci::Pipeline.config_sources
    enum :failure_reason, Enums::Ci::Pipeline.failure_reasons
    enum :locked, { unlocked: 0, artifacts_locked: 1 }

    belongs_to :project, inverse_of: :all_pipelines
    belongs_to :trigger, class_name: 'Ci::Trigger', inverse_of: :pipelines, optional: true
    belongs_to :pipeline_schedule, class_name: 'Ci::PipelineSchedule', optional: true

    belongs_to :user
    belongs_to :merge_request, class_name: 'MergeRequest', optional: true
    belongs_to :ci_ref, class_name: 'Ci::Ref', foreign_key: :ci_ref_id, inverse_of: :pipelines, optional: true

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :stages, inverse_of: :pipeline
    has_many :bridges, class_name: 'Ci::Bridge', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :builds, inverse_of: :pipeline
    has_many :messages, class_name: 'Ci::PipelineMessage', inverse_of: :pipeline

    has_one :pipeline_config, class_name: 'Ci::PipelineConfig', inverse_of: :pipeline
    has_one :pipeline_metadata, class_name: 'Ci::PipelineMetadata', inverse_of: :pipeline, dependent: :destroy
    has_many :all_jobs, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, dependent: :destroy
    has_many :current_jobs, -> { latest }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :all_processable_jobs, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :current_processable_jobs, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline
    delegate :name, to: :pipeline_metadata, allow_nil: true
    has_many :pending_builds, -> { pending }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :failed_builds, -> {
      latest.failed
    }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline

    scope :for_status, ->(status) { where(status: status) }
    scope :created_after, ->(time) { where(arel_table[:created_at].gt(time)) }
    scope :created_before, ->(time) { where(arel_table[:created_at].lt(time)) }
    scope :ci_sources, -> { where(source: Enums::Ci::Pipeline.ci_sources.values) }
    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_pipeline_id,
      inverse_of: :source_pipeline
    has_one :source_pipeline, class_name: 'Ci::Sources::Pipeline', inverse_of: :pipeline
    has_one :parent_pipeline, -> { merge(Ci::Sources::Pipeline.same_project) }, through: :source_pipeline, source: :source_pipeline
    has_one :source_bridge, through: :source_pipeline, source: :source_bridge

    # Returns the pipelines that associated with the given merge request.
    # In general, please use `Ci::PipelinesForMergeRequestFinder` instead,
    # for checking permission of the actor.
    scope :triggered_by_merge_request, ->(merge_request) do
      where(
        source: :merge_request_event,
        merge_request: merge_request,
        project: [merge_request.source_project, merge_request.target_project]
      )
    end
    scope :ci_branch_sources, -> { where(source: Enums::Ci::Pipeline.ci_branch_sources.values) }
    scope :for_ref, ->(ref) { where(ref: ref) }
    # yeh, when you inherit the codes, you also get the Blue Cheese
    scope :for_branch, ->(branch) { for_ref(branch).where(tag: false) }
    scope :for_source_sha, ->(source_sha) { where(source_sha: source_sha) }
    scope :for_sha, ->(sha) { where(sha: sha) }
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_sha_or_source_sha, ->(sha) { for_sha(sha).or(for_source_sha(sha)) }

    scope :order_id_asc, -> { order(id: :asc) }
    scope :order_id_desc, -> { order(id: :desc) }

    scope :conservative_interruptible, -> do
      where_not_exists(
        Ci::Build.scoped_pipeline.with_status(STARTED_STATUSES).not_interruptible
      )
    end

    has_internal_id :iid, scope: :project, presence: false,
      track_if: -> { !importing? },
      ensure_if: -> { !importing? },
      init: lambda { |pipeline, scope|
        if pipeline
          pipeline.project&.all_pipelines&.maximum(:iid) || pipeline.project&.all_pipelines&.count
        elsif scope
          ::Ci::Pipeline.where(**scope).maximum(:iid)
        end
      }
    # This is used to retain access to the method defined by `Ci::HasRef`
    # before being overridden in this class.
    alias_method :jobs_git_ref, :git_ref

    state_machine :status, initial: :created do
      event :enqueue do
        transition %i[created manual waiting_for_resource preparing skipped scheduled] => :pending
        transition %i[success failed canceling canceled] => :running

        # this is needed to ensure tests to be covered
        transition [:running] => :running
        transition [:waiting_for_callback] => :waiting_for_callback
      end

      event :request_resource do
        transition any - [:waiting_for_resource] => :waiting_for_resource
      end

      event :prepare do
        transition any - [:preparing] => :preparing
      end

      event :run do
        transition any - [:running] => :running
      end

      event :wait_for_callback do
        transition any - [:waiting_for_callback] => :waiting_for_callback
      end

      event :skip do
        transition any - [:skipped] => :skipped
      end

      event :drop do
        transition any - [:failed] => :failed
      end

      event :succeed do
        # A success pipeline can also be retried, for example; a pipeline with a failed manual job.
        # When retrying the pipeline, the status of the pipeline is not changed because the failed
        # manual job transitions to the `manual` status.
        # More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98967#note_1144718316
        transition any => :success
      end

      event :start_cancel do
        transition any - %i[canceling canceled] => :canceling
      end

      event :cancel do
        transition any - [:canceled] => :canceled
      end

      event :block do
        transition any - [:manual] => :manual
      end

      event :delay do
        transition any - [:scheduled] => :scheduled
      end

      # IMPORTANT
      # Do not add any operations to this state_machine
      # Create a separate worker for each new operation

      before_transition %i[created waiting_for_resource preparing pending] => :running do |pipeline|
        pipeline.started_at ||= Time.current
      end

      before_transition any => %i[success failed canceled] do |pipeline|
        pipeline.finished_at = Time.current
        pipeline.update_duration
      end

      before_transition any => [:manual] do |pipeline|
        pipeline.update_duration
      end

      before_transition canceled: any - [:canceled] do |pipeline|
        pipeline.auto_canceled_by = nil
      end

      before_transition any => :failed do |pipeline, transition|
        transition.args.first.try do |reason|
          pipeline.failure_reason = reason
        end
      end
    end

    def importing?
      false
    end

    def created_successfully?
      persisted? && failure_reason.blank?
    end

    def self.ransackable_attributes(_auth_object = nil)
      %w[sha status ref]
    end

    def update_duration
      return unless started_at

      self.duration = Gitlab::Ci::Pipeline::Duration.from_pipeline(self)
    end

    def self.jobs_count_in_alive_pipelines
      created_after(24.hours.ago).alive.joins(:builds).count
    end

    def total_size
      builds.count(:id)
    end

    def pipeline_schedule; end

    def short_sha
      Ci::Pipeline.truncate_sha(sha)
    end

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def ensure_ci_ref!
      self.ci_ref = Ci::Ref.ensure_for(self)
    end

    def merge_request?
      merge_request_id.present? && merge_request.present?
    end

    def source_ref_path
      if branch? || merge_request?
        Gitlab::Git::BRANCH_REF_PREFIX + source_ref.to_s
      elsif tag?
        Gitlab::Git::TAG_REF_PREFIX + source_ref.to_s
      end
    end

    def source_ref
      if merge_request?
        merge_request.source_branch
      else
        ref
      end
    end

    def source_ref_slug
      Gitlab::Utils.slugify(source_ref.to_s)
    end

    def protected_ref?
      strong_memoize(:protected_ref) { project.protected_for?(git_ref) }
    end

    def add_error_message(content)
      add_message(:error, content)
    end

    def add_warning_message(content)
      add_message(:warning, content)
    end

    def variables_builder
      @variables_builder ||= ::Gitlab::Ci::Variables::Builder.new(self)
    end

    def only_workload_variables?
      Enums::Ci::Pipeline.workload_sources.key?(source.to_sym)
    end

    def has_kubernetes_active?
      false
    end

    def freeze_period?
      false
    end

    def external_pull_request?
      false
    end

    def self.last_finished_for_ref_id(ci_ref_id)
      where(ci_ref_id: ci_ref_id).ci_sources.finished.order(id: :desc).select(:id).take
    end

    # Like #drop!, but does not persist the pipeline nor trigger any state
    # machine callbacks.
    def set_failed(failure_reason)
      self.failure_reason = failure_reason.to_s
      self.status = 'failed'
    end

    def cancelable?
      statuses.cancelable.any? && source != 'external'
    end

    def auto_cancel_on_new_commit
      pipeline_metadata&.auto_cancel_on_new_commit || 'conservative'
    end

    def auto_cancel_on_job_failure
      pipeline_metadata&.auto_cancel_on_job_failure || 'none'
    end

    def cancel_async_on_job_failure
      case auto_cancel_on_job_failure
      when 'none'
        # no-op
      when 'all'
        ::Ci::UserCancelPipelineWorker.perform_async(id, id, user.id)
      else
        raise ArgumentError,
          "Unknown auto_cancel_on_job_failure value: #{auto_cancel_on_job_failure}"
      end
    end

    # rubocop: disable Metrics/CyclomaticComplexity -- breaking apart hurts readability
    def set_status(new_status)
      retry_optimistic_lock(self, name: 'ci_pipeline_set_status') do
        case new_status
        when 'created' then nil
        when 'waiting_for_resource' then request_resource
        when 'preparing' then prepare
        when 'waiting_for_callback' then wait_for_callback
        when 'pending' then enqueue
        when 'running' then run
        when 'success' then succeed
        when 'failed' then drop
        when 'canceling' then start_cancel
        when 'canceled' then cancel
        when 'skipped' then skip
        when 'manual' then block
        when 'scheduled' then delay
        else
          raise Ci::HasStatus::UnknownStatusError, "Unknown status `#{new_status}`"
        end
      end
    end
    # rubocop: enable Metrics/CyclomaticComplexity

    # Without using `unscoped`, caller scope is also included into the query.
    # Using `unscoped` here will be redundant after Rails 6.1
    def object_hierarchy(options = {})
      ::Gitlab::Ci::PipelineObjectHierarchy
        .new(self.class.unscoped.where(id: id), options: options)
    end

    def self_and_downstreams
      object_hierarchy.base_and_descendants
    end

    def self_and_upstreams
      object_hierarchy.base_and_ancestors
    end

    def child?
      parent_pipeline? && parent_pipeline.present?
    end

    # With only parent-child pipelines
    def self_and_project_ancestors
      object_hierarchy(project_condition: :same).base_and_ancestors
    end

    # Follow the upstream pipeline relationships, regardless of multi-project or
    # parent-child, and return the top-level ancestor.
    def upstream_root
      @upstream_root ||= object_hierarchy.base_and_ancestors(hierarchy_order: :desc).first
    end

    # Applies to all parent-child and multi-project pipelines
    def complete_hierarchy_count
      upstream_root.self_and_downstreams.count
    end

    private

    def add_message(severity, content)
      messages.build(severity: severity, content: content, project_id: project_id)
    end
  end
end
