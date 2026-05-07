# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Participable
  extend ActiveSupport::Concern

  class_methods do
    # Adds a list of participant attributes. Attributes can either be symbols or
    # Procs.
    #
    # When using a Proc instead of a Symbol the Proc will be given two
    # arguments:
    #
    # 1. The current user (as an instance of User)
    # 2. An instance of `Gitlab::ReferenceExtractor`
    #
    # It is expected that a Proc populates the given reference extractor
    # instance with data. The return value of the Proc is ignored.
    #
    # attr - The name of the attribute or a Proc
    def participant(attr)
      participant_attrs << attr
    end
  end

  included do
    # Accessor for participant attributes.
    cattr_accessor :participant_attrs, instance_accessor: false do
      []
    end
  end

  def participants(_user = nil)
    result = []
    result << author if respond_to?(:author)
    result += assignees.to_a if respond_to?(:assignees)
    result.compact.uniq
  end
end
