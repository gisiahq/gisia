# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Ssh
  class PostReceive
    def execute(gl_repository, identifier, changes, push_options = {})
      container, = Gitlab::GlRepository.parse(gl_repository)
      changes = Base64.decode64(changes) unless changes.include?(' ')
      post_received = Gitlab::GitPostReceive.new(container, identifier, changes, push_options)
      process_project_changes(post_received, container)
    end

    private

    def identify_user(post_received)
      post_received.identify.tap do |user|
        log("Triggered hook for non-existing user \"#{post_received.identifier}\"") unless user
      end
    end

    def process_project_changes(post_received, project)
      user = identify_user(post_received)
      return false unless user

      push_options = post_received.push_options
      changes = post_received.changes
      expire_ref_caches(project, changes)

      process_ref_changes(project, user, push_options: push_options, changes: changes)
    end

    def expire_ref_caches(project, changes)
      project.repository&.expire_branches_cache if changes.branch_changes.any?
      project.repository&.expire_tags_cache if changes.tag_changes.any?
    end

    def process_ref_changes(project, user, params = {})
      return unless params[:changes].any?

      Git::Ref.new(project, user, params).push
    end
  end
end
