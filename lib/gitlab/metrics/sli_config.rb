# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Metrics
    module SliConfig
      RegisterClass = Data.define(:klass, :is_runtime_enabled_block) do
        def enabled_class
          klass if is_runtime_enabled_block.call
        end
      end

      def self.registered_classes
        @registered_classes ||= Set.new
      end

      def self.enabled_slis
        SliConfig.registered_classes.filter_map(&:enabled_class)
      end

      def self.register(register_class)
        Gitlab::AppLogger.info "#{self} registering #{register_class.klass}, runtime=#{Gitlab::Runtime.safe_identify}"
        SliConfig.registered_classes << register_class
      end

      module ConfigMethods
        def puma_enabled!(enable = true)
          register_class = RegisterClass.new(self, -> { enable && Gitlab::Runtime.puma? })
          SliConfig.register(register_class)
        end

        def sidekiq_enabled!(enable = true)
          register_class = RegisterClass.new(self, -> { enable && Gitlab::Runtime.sidekiq? })
          SliConfig.register(register_class)
        end
      end

      def self.included(base)
        base.extend(ConfigMethods)
      end
    end
  end
end

