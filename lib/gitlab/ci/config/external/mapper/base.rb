# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      module External
        class Mapper
          # Base class for mapper classes
          class Base
            def initialize(context)
              @context = context
            end

            def process(...)
              context.logger.instrument(mapper_instrumentation_key) do
                process_without_instrumentation(...)
              end
            end

            private

            attr_reader :context

            def process_without_instrumentation
              raise NotImplementedError
            end

            def mapper_instrumentation_key
              :"config_mapper_#{self.class.name.demodulize.downcase}"
            end
          end
        end
      end
    end
  end
end
