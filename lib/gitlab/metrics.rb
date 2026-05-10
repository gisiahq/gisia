# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

# Only for calling, no feature
module Gitlab
  module Metrics
    class << self
      def gauge(*_args)
        Object.new.tap do |obj|
          def obj.set(*_args)
            0
          end
        end
      end

      def histogram(*_args)
        Object.new.tap do |obj|
          def obj.observe(*_args); end
        end
      end

      def counter(*_args)
        Object.new.tap do |obj|
          def obj.increment(*_args)
            0
          end
        end
      end

      def measure(*_args)
        yield
      end

      def add_event(*_args); end
    end
  end
end
