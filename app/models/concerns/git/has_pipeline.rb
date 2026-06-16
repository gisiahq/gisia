# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Git
  module HasPipeline
    extend ActiveSupport::Concern

    def create_pipelines!
      Ci::Pipeline.build_from(project, current_user, pipeline_params, :push, pipeline_options)
    end

    private

    def change
      @change ||= OpenStruct.new(params[:change])
    end

    def pipeline_params
      strong_memoize(:pipeline_params) do
        {
          before: oldrev,
          after: newrev,
          ref: ref,
          variables_attributes: generate_vars_from_push_options || [],
          push_options: params[:push_options] || {},
          checkout_sha: Gitlab::DataBuilder::Push.checkout_sha(
            project.repository, newrev, ref
          )
        }
      end
    end

    def generate_vars_from_push_options
      return [] unless ci_variables_from_push_options

      ci_variables_from_push_options.map do |var_definition, _count|
        key, value = var_definition.to_s.split('=', 2)

        # Accept only valid format. We ignore the following formats
        # 1. "=123". In this case, `key` will be an empty string
        # 2. "FOO". In this case, `value` will be nil.
        # However, the format "FOO=" will result in key being `FOO` and value
        # being an empty string. This is acceptable.
        next if key.blank? || value.nil?

        { 'key' => key, 'variable_type' => 'env_var', 'secret_value' => value }
      end.compact
    end

    def push_options
      strong_memoize(:push_options) do
        params[:push_options]&.deep_symbolize_keys
      end
    end

    def ci_variables_from_push_options
      strong_memoize(:ci_variables_from_push_options) do
        push_options&.dig(:ci, :variable)
      end
    end

    def pipeline_options
      return {} unless ci_inputs_from_push_options

      {
        inputs: generate_ci_inputs_from_push_options || {}
      }
    end

    def ci_inputs_from_push_options
      strong_memoize(:ci_inputs_from_push_options) do
        push_options&.dig(:ci, :input)
      end
    end

    def generate_ci_inputs_from_push_options
      return {} unless ci_inputs_from_push_options

      params = ci_inputs_from_push_options.map do |input, _|
        input.to_s.split('=', 2)
      end

      ::Ci::PipelineCreation::Inputs.parse_params(params.to_h)
    end
  end
end
