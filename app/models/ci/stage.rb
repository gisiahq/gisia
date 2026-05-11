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
  class Stage < ApplicationRecord
    include Ci::HasStatus

    has_many :builds
    enum :status, Ci::HasStatus::STATUSES_ENUM

    attr_accessor :partition_id

    belongs_to :project
    belongs_to :pipeline, foreign_key: :pipeline_id, inverse_of: :stages

    has_many :statuses,
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
    has_many :bridges,
      foreign_key: :stage_id,
      inverse_of: :ci_stage

    scope :ordered, -> { order(position: :asc) }

    after_initialize do
      self.status = DEFAULT_STATUS if self.status.nil?
    end

    state_machine :status do
      event :enqueue do
        transition any - [:pending] => :pending
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
        transition any - [:success] => :success
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
    end

    # rubocop: disable Metrics/CyclomaticComplexity -- breaking apart hurts readability, consider refactoring issue #439268
    def set_status(new_status)
      Gitlab::OptimisticLocking.retry_lock(self, name: 'ci_stage_set_status') do
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
        when 'manual' then block
        when 'scheduled' then delay
        when 'skipped', nil then skip
        else
          raise Ci::HasStatus::UnknownStatusError, "Unknown status `#{new_status}`"
        end
      end
    end
    # rubocop: enable Metrics/CyclomaticComplexity
  end
end

