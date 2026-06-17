# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Namespaces
  class ProjectNamespace < Namespace
    has_one :project, inverse_of: :namespace, foreign_key: :namespace_id
    has_many :members, foreign_key: :namespace_id, dependent: :destroy, class_name: 'ProjectMember'
    has_many :members_and_requesters, foreign_key: :namespace_id, class_name: 'ProjectMember'
    has_many :project_members, -> { non_request }, dependent: :delete_all, foreign_key: :namespace_id
    has_many :users, through: :project_members
    has_many :variables, class_name: 'Ci::Variable', foreign_key: :namespace_id, dependent: :destroy
    has_many :work_items, foreign_key: :namespace_id, dependent: :destroy
    has_many :issues, class_name: 'Issue', foreign_key: :namespace_id, dependent: :destroy
    has_many :epics, class_name: 'Epic', foreign_key: :namespace_id, dependent: :destroy

    accepts_nested_attributes_for :project

    delegate :importing?, to: :project

    after_commit :init_member

    def self.sti_name
      'Project'
    end

    def self.polymorphic_name
      'Namespaces::ProjectNamespace'
    end

    def enabled_git_access_protocol
      'all'
    end

    def team
      @team ||= ProjectTeam.new(project)
    end

    def pin_class
      Namespaces::ProjectNamespacePin
    end
  end
end
