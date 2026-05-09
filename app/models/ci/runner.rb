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
  class Runner < Ci::ApplicationRecord
    prepend Ci::BulkInsertableTags
    include Gitlab::SQL::Pattern
    include FromUnion
    include TokenAuthenticatable
    include Gitlab::Utils::StrongMemoize
    include TaggableQueries
    include Presentable
    include EachBatch
    include Ci::HasRunnerStatus
    include Ci::Taggable
    include Ci::Runners::Registrable
    include Ci::Runners::HasBuilds
    include Ci::Builds::Queueable
    include Ci::Runners::HasVariables

    extend ::Gitlab::Utils::Override

    attribute :run_untagged, :boolean, default: true

    add_authentication_token_field :token,
      encrypted: :required,
      expires_at: :compute_token_expiration,
      format_with_prefix: :prefix_for_new_and_legacy_runner

    enum :access_level, {
      not_protected: 0,
      ref_protected: 1
    }

    enum :runner_type, {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }

    enum :creation_state, {
      started: 0,
      finished: 100
    }, suffix: true

    enum :registration_type, {
      registration_token: 0,
      authenticated_user: 1
    }, suffix: true

    RUNNER_SHORT_SHA_LENGTH = 8

    # This `ONLINE_CONTACT_TIMEOUT` needs to be larger than
    #   `RUNNER_QUEUE_EXPIRY_TIME+UPDATE_CONTACT_COLUMN_EVERY`
    #
    ONLINE_CONTACT_TIMEOUT = 2.hours

    # The `RUNNER_QUEUE_EXPIRY_TIME` indicates the longest interval that
    #   Runner request needs to be refreshed by Rails instead of being handled
    #   by Workhorse
    RUNNER_QUEUE_EXPIRY_TIME = 1.hour

    # The `UPDATE_CONTACT_COLUMN_EVERY` defines how often the Runner DB entry can be updated
    UPDATE_CONTACT_COLUMN_EVERY = ((40.minutes)..(55.minutes))

    # The `STALE_TIMEOUT` constant defines the how far past the last contact or creation date a runner will be considered stale
    STALE_TIMEOUT = 7.days

    # Only allow authentication token to be visible for a short while
    REGISTRATION_AVAILABILITY_TIME = 1.hour

    AVAILABLE_TYPES_LEGACY = %w[specific shared].freeze
    AVAILABLE_TYPES = runner_types.keys.freeze
    DEPRECATED_STATUSES = %w[active paused].freeze # TODO: Remove in REST v5. Relevant issue: https://gitlab.com/gitlab-org/gitlab/-/issues/344648
    AVAILABLE_STATUSES = %w[online offline never_contacted stale].freeze
    AVAILABLE_STATUSES_INCL_DEPRECATED = (DEPRECATED_STATUSES + AVAILABLE_STATUSES).freeze
    AVAILABLE_SCOPES = (AVAILABLE_TYPES_LEGACY + AVAILABLE_TYPES + AVAILABLE_STATUSES_INCL_DEPRECATED).freeze

    FORM_EDITABLE = %i[description tag_list active run_untagged locked access_level
                       maximum_timeout_human_readable].freeze
    MINUTES_COST_FACTOR_FIELDS = %i[public_projects_minutes_cost_factor private_projects_minutes_cost_factor].freeze

    TAG_LIST_MAX_LENGTH = 50

    has_many :runner_managers, inverse_of: :runner
    has_many :builds
    has_many :running_builds, inverse_of: :runner
    has_many :taggings, class_name: 'Ci::RunnerTagging', inverse_of: :runner
    has_many :tags, class_name: 'Ci::Tag', through: :taggings, source: :tag

    # currently we have only 1 namespace assigned, but order is here for consistency
    has_one :owner_runner_namespace, -> { order(:id) }, class_name: 'Ci::RunnerNamespace'

    has_one :last_build, -> { order('id DESC') }, class_name: 'Ci::Build'

    belongs_to :creator, class_name: 'User', optional: true

    before_save :ensure_token
    after_destroy :cleanup_runner_queue

    scope :active, ->(value = true) { where(active: value) }

    def heartbeat(creation_state: nil)
      values = { contacted_at: Time.current }
      values[:creation_state] = creation_state if creation_state.present?

      # We save data without validation, it will always change due to `contacted_at`
      update_columns(values) if persist_cached_data?
    end

    def persist_cached_data?
      # Use a random threshold to prevent beating DB updates.
      contacted_at_max_age = Random.rand(UPDATE_CONTACT_COLUMN_EVERY)

      real_contacted_at = read_attribute(:contacted_at)
      real_contacted_at.nil? ||
        (Time.current - real_contacted_at) >= contacted_at_max_age
    end

    def ensure_manager(system_xid) # -- This is used only in API endpoints outside of transactions
      RunnerManager.safe_find_or_create_by!(runner_id: id, system_xid: system_xid.to_s) do |m|
        m.runner_type = runner_type
      end
    end

    def ensure_runner_queue_value
      new_value = SecureRandom.hex
      ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_value,
        expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: false)
    end

    def runner_queue_value_latest?(value)
      ensure_runner_queue_value == value if value.present?
    end

    def cleanup_runner_queue
      ::Gitlab::Workhorse.cleanup_key(runner_queue_key)
    end

    def runner_queue_key
      "runner:build_queue:#{token}"
    end

    def registration_available?
      authenticated_user_registration_type? &&
        created_at > REGISTRATION_AVAILABILITY_TIME.ago &&
        creation_state == 'started'
    end

    def matches_build?(build)
      runner_matcher.matches?(build.build_matcher)
    end

    def runner_matcher
      Gitlab::Ci::Matching::RunnerMatcher.new({
        runner_ids: [id],
        runner_type: runner_type,
        public_projects_minutes_cost_factor: public_projects_minutes_cost_factor,
        private_projects_minutes_cost_factor: private_projects_minutes_cost_factor,
        run_untagged: run_untagged,
        access_level: access_level,
        tag_list: tag_list,
        allowed_plan_ids: allowed_plan_ids
      })
    end
    strong_memoize_attr :runner_matcher

    def self.online_contact_time_deadline
      ONLINE_CONTACT_TIMEOUT.ago
    end

    def self.stale_deadline
      STALE_TIMEOUT.ago
    end

    def tick_runner_queue
      SecureRandom.hex.tap do |new_update|
        ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_update,
          expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: true)
      end
    end

    def match_build_if_online?(build)
      active? && online? && matches_build?(build)
    end

    def matches_build?(build)
      runner_matcher.matches?(build.build_matcher)
    end

    def runner_matcher
      Gitlab::Ci::Matching::RunnerMatcher.new({
        runner_ids: [id],
        runner_type: runner_type,
        public_projects_minutes_cost_factor: public_projects_minutes_cost_factor,
        private_projects_minutes_cost_factor: private_projects_minutes_cost_factor,
        run_untagged: run_untagged,
        access_level: access_level,
        tag_list: tag_list,
        allowed_plan_ids: []
      })
    end

    def public_projects_minutes_cost_factor
      1.0
    end

    def private_projects_minutes_cost_factor
      1.0
    end
  end
end
