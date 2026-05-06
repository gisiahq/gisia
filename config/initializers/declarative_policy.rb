# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025 Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

require 'declarative_policy'

# This module speeds up class resolution by caching it.
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119924
# See https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/issues/30
module ClassForClassCache
  def self.prepended(base)
    class << base
      attr_accessor :class_for_class_cache
    end

    base.class_for_class_cache = {}
    base.singleton_class.prepend(SingletonClassMethods)
  end

  module SingletonClassMethods
    def class_for_class(subject_class)
      class_for_class_cache.fetch(subject_class) do
        class_for_class_cache[subject_class] = super
      end
    end
  end
end
Rails.application.config.to_prepare do
  DeclarativePolicy.configure do
    named_policy :global, ::GlobalPolicy
  end
end

DeclarativePolicy.prepend(ClassForClassCache)
