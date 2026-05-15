# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Ci
  module JobArtifacts
    class TrackArtifactReportService
      include Gitlab::Utils::UsageData

      REPORT_TRACKED = %i[test coverage].freeze

      def execute(pipeline)
        REPORT_TRACKED.each do |report|
          if pipeline.complete_and_has_reports?(Ci::JobArtifact.of_report_type(report))
            track_usage_event(event_name(report), pipeline.user_id)
          end
        end
      end

      def event_name(report)
        "i_testing_#{report}_report_uploaded"
      end
    end
  end
end
