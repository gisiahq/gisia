# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
# ======================================================

module Gitlab
  module Ci
    class Config
      class Extendable
        include Enumerable

        ExtensionError = Class.new(StandardError)

        def initialize(hash)
          @hash = hash.to_h.deep_dup

          each { |entry| entry.extend! if entry.extensible? }
        end

        def each
          @hash.each_key do |key|
            yield Extendable::Entry.new(key, @hash)
          end
        end

        def to_hash
          @hash.to_h
        end
      end
    end
  end
end
