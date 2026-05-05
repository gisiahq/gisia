# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module GitalyClient
    class RefCollectionWithNextCursor < SimpleDelegator
      include Enumerable

      def initialize(response)
        # Last non-empty cursor from the stream is the pagination cursor
        refs = response.flat_map do |message|
          cursor = message.pagination_cursor&.next_cursor
          @next_cursor = cursor if cursor.present?

          message.references.to_ary
        end

        super(refs)
      end

      attr_reader :next_cursor

      def each(&block)
        __getobj__.each(&block)
      end
    end
  end
end
