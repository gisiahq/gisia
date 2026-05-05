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
  class Build < Processable
    extend MethodOverrideGuard
    include Ci::HasRef
    include Ci::Taggable
    include Ci::Contextable
    include Ci::HasBuildStatus
    include Ci::Builds::Queueable
    include Ci::Builds::HasVariables
    include Ci::Builds::Deployable
    include Ci::Builds::StateUpdateable
    include Ci::Builds::Traceable
    include Ci::Builds::TraceArchivable

    TOKEN_PREFIX = 'gscbt-'
    RUNNERS_STATUS_CACHE_EXPIRATION = 1.minute

    has_one :runner_manager_build,
      class_name: 'Ci::RunnerManagerBuild',
      foreign_key: :build_id,
      inverse_of: :build,
      autosave: true

    has_one :runner_manager, foreign_key: :runner_machine_id, through: :runner_manager_build,
      class_name: 'Ci::RunnerManager'
    has_one :runner_session, class_name: 'Ci::BuildRunnerSession', validate: true, foreign_key: :build_id,
      inverse_of: :build
    has_one :trace_metadata, class_name: 'Ci::BuildTraceMetadata', foreign_key: :build_id, inverse_of: :build
    has_one :pending_state, class_name: 'Ci::BuildPendingState', foreign_key: :build_id, inverse_of: :build
    has_one :build_source, class_name: 'Ci::BuildSource', foreign_key: :build_id, inverse_of: :build
    has_one :queuing_entry, class_name: 'Ci::PendingBuild', foreign_key: :build_id, dependent: :delete, inverse_of: :build

    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_job_id, inverse_of: :build

    Ci::JobArtifact.file_types.each_key do |key|
      has_one :"job_artifacts_#{key}", -> { with_file_types([key]) },
        class_name: 'Ci::JobArtifact',
        foreign_key: :job_id,
        inverse_of: :job
    end

    has_many :statuses,
      class_name: 'CommitStatus',
      foreign_key: :stage_id,
      inverse_of: :ci_stage
    has_many :latest_statuses,
      class_name: 'CommitStatus',
      foreign_key: :stage_id,
      inverse_of: :ci_stage
    has_many :retried_statuses,
      class_name: 'CommitStatus',
      foreign_key: :stage_id,
      inverse_of: :ci_stage
    has_many :processables,
      class_name: 'Ci::Processable',
      foreign_key: :stage_id,
      inverse_of: :ci_stage
    has_many :builds,
      foreign_key: :stage_id,
      inverse_of: :ci_stage
    has_many :trace_chunks,
      class_name: 'Ci::BuildTraceChunk',
      foreign_key: :build_id,
      inverse_of: :build
    # Projects::DestroyService destroys Ci::Pipelines, which use_fast_destroy on :job_artifacts
    # before we delete builds. By doing this, the relation should be empty and not fire any
    # DELETE queries when the Ci::Build is destroyed. The next step is to remove `dependent: :destroy`.
    # Details: https://gitlab.com/gitlab-org/gitlab/-/issues/24644#note_689472685 # -- See above
    has_many :job_artifacts,
      class_name: 'Ci::JobArtifact',
      foreign_key: :job_id,
      dependent: :destroy,
      inverse_of: :job

    belongs_to :project, inverse_of: :builds
    belongs_to :runner, optional: true
    belongs_to :pipeline,
      class_name: 'Ci::Pipeline',
      foreign_key: :commit_id,
      inverse_of: :builds
    belongs_to :execution_config,
      class_name: 'Ci::BuildExecutionConfig',
      foreign_key: :execution_config_id,
      inverse_of: :builds, optional: true

    scope :finished_before, ->(date) { finished.where('finished_at < ?', date) }
    scope :eager_load_for_archiving_trace, -> { preload(:project, :pending_state) }
    scope :without_archived_trace, -> { where_not_exists(Ci::JobArtifact.scoped_build.trace) }

    add_authentication_token_field :token,
      encrypted: :required,
      format_with_prefix: :prefix_and_partition_for_token

    delegate :ensure_persistent_ref, to: :pipeline
    delegate :name, to: :project, prefix: true

    def clone(current_user:, new_job_variables_attributes: [])
      new_build = super

      if action? && new_job_variables_attributes.any?
        new_build.job_variables = []
        new_build.job_variables_attributes = new_job_variables_attributes
      end

      new_build
    end

    def self.clone_accessors
      %i[pipeline project ref tag options name
         allow_failure stage_idx
         yaml_variables when environment coverage_regex
         description protected needs_attributes
         job_variables_attributes
         scheduling_type ci_stage partition_id execution_config_id].freeze
    end

    def job_variables_attributes
      strong_memoize(:job_variables_attributes) do
        job_variables.internal_source.map do |variable|
          variable.attributes.except('id', 'job_id', 'encrypted_value', 'encrypted_value_iv').tap do |attrs|
            attrs[:value] = variable.value
          end
        end
      end
    end

    def auto_retry
      strong_memoize(:auto_retry) do
        Gitlab::Ci::Build::AutoRetry.new(self)
      end
    end

    def auto_retry_allowed?
      auto_retry.allowed?
    end

    def auto_retry_expected?
      failed? && auto_retry_allowed?
    end

    def can_auto_cancel_pipeline_on_job_failure?
      # A job that doesn't need to be auto-retried can auto-cancel its own pipeline
      !auto_retry_expected?
    end

    def any_unmet_prerequisites?
      false
    end

    def partition_id_prefix_in_16_bit_encode
      "#{partition_id.to_s(16)}_"
    end

    def prefix_and_partition_for_token
      TOKEN_PREFIX + partition_id_prefix_in_16_bit_encode
    end

    def all_queuing_entries
      ::Ci::PendingBuild.where(build_id: id)
    end

    def create_queuing_entry!
      ::Ci::PendingBuild.upsert_from_build!(self)
    end

    def allow_git_fetch
      project.build_allow_git_fetch
    end

    def time_in_queue_seconds
      return if queued_at.nil?

      (::Time.current - queued_at).seconds.to_i
    end
    strong_memoize_attr :time_in_queue_seconds

    def source
      build_source&.source || pipeline.source
    end
    strong_memoize_attr :source

    def repo_url
      return unless token

      auth = "#{::Gitlab::Auth::CI_JOB_USER}:#{token}@"
      project.http_url_to_repo.sub(%r{^https?://}) do |prefix|
        prefix + auth
      end
    end

    def runnable?
      true
    end

    def steps
      [Gitlab::Ci::Build::Step.from_commands(self),
       Gitlab::Ci::Build::Step.from_release(self),
       Gitlab::Ci::Build::Step.from_after_script(self)].compact
    end

    def runtime_hooks
      Gitlab::Ci::Build::Hook.from_hooks(self)
    end

    def image
      Gitlab::Ci::Build::Image.from_image(self)
    end

    def services
      Gitlab::Ci::Build::Image.from_services(self)
    end

    def cache
      cache = Array.wrap(options[:cache])

      cache.each do |single_cache|
        single_cache[:fallback_keys] = [] unless single_cache.key?(:fallback_keys)
      end

      if project.jobs_cache_index
        cache = cache.map do |single_cache|
          cache = single_cache.merge(key: "#{single_cache[:key]}-#{project.jobs_cache_index}")
          fallback = cache.slice(:fallback_keys).transform_values do |keys|
            keys.map do |key|
              "#{key}-#{project.jobs_cache_index}"
            end
          end
          cache.merge(fallback.compact)
        end
      end

      return cache unless project.ci_separated_caches

      cache.map do |entry|
        type_suffix = !entry[:unprotect] && pipeline.protected_ref? ? 'protected' : 'non_protected'

        cache = entry.merge(key: "#{entry[:key]}-#{type_suffix}")
        fallback = cache.slice(:fallback_keys).transform_values do |keys|
          keys.map do |key|
            "#{key}-#{type_suffix}"
          end
        end
        cache.merge(fallback.compact)
      end
    end

    def credentials
      Gitlab::Ci::Build::Credentials::Factory.new(self).create!
    end

    def features
      {
        trace_sections: true,
        failure_reasons: self.class.failure_reasons.keys
      }
    end

    def erased?
      !erased_at.nil?
    end

    def needs_touch?
      Time.current - updated_at > 15.minutes.to_i
    end

    def drop_with_exit_code!(failure_reason, exit_code)
      failure_reason ||= :unknown_failure
      drop!(::Gitlab::Ci::Build::Status::Reason.new(self, failure_reason, exit_code))
    end

    def allowed_to_fail_with_code?(exit_code)
      options
        .dig(:allow_failure_criteria, :exit_codes)
        .to_a
        .include?(exit_code)
    end

    def exit_code=(value)
      return unless value

      ensure_metadata.exit_code = value.to_i.clamp(0, Gitlab::Database::MAX_SMALLINT_VALUE)
    end

    def status_commit_hooks
      @status_commit_hooks ||= []
    end

    def run_on_status_commit(&block)
      status_commit_hooks.push(block)
    end

    def all_runtime_metadata
      ::Ci::RunningBuild.where(build_id: id)
    end

    def any_runners_online?
      cache_for_online_runners do
        project.any_online_runners? { |runner| runner.match_build_if_online?(self) }
      end
    end

    def stuck?
      pending? && !any_runners_online?
    end

    def doom!
      transaction do
        now = Time.current
        attrs = { status: :failed, failure_reason: :data_integrity_failure, updated_at: now }
        attrs[:finished_at] = now unless finished_at.present?
        update_columns(attrs)
        all_queuing_entries.delete_all
        all_runtime_metadata.delete_all
      end

      Gitlab::AppLogger.info(
        message: 'Build doomed',
        class: self.class.name,
        build_id: id,
        pipeline_id: pipeline_id,
        project_id: project_id
      )
    end

    def hide_secrets(data, _metrics = ::Gitlab::Ci::Trace::Metrics.new)
      # Todo,
      data
    end

    def available_artifacts?
      false
    end

    def ensure_trace_metadata!
      Ci::BuildTraceMetadata.find_or_upsert_for!(id, project_id)
    end

    def remove_pending_state!
      pending_state.try(:delete)
    end

    def remove_token!
      update!(token_encrypted: nil)
    end

    def build_matcher
      strong_memoize(:build_matcher) do
        Gitlab::Ci::Matching::BuildMatcher.new({
          protected: protected?,
          tag_list: tag_list,
          build_ids: [id],
          project: project
        })
      end
    end

    protected

    def run_status_commit_hooks!
      status_commit_hooks.reverse_each do |hook|
        instance_eval(&hook)
      end
    end

    private

    def cache_for_online_runners(&block)
      Rails.cache.fetch(
        ['has-online-runners', id],
        expires_in: RUNNERS_STATUS_CACHE_EXPIRATION
      ) { yield }
    end
  end
end
