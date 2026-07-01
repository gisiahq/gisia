# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class NotePolicy < BasePolicy
  delegate { @subject.resource_parent }

  condition(:is_author) { @user && @subject.author == @user }
  condition(:can_read_noteable) { can?(:"read_#{@subject.noteable_ability_name}") }

  # Anyone who can read the noteable (issue, etc.) can read its notes.
  rule { can_read_noteable }.enable :read_note

  rule { ~can_read_noteable }.policy do
    prevent :read_note
    prevent :admin_note
  end

  rule { is_author }.policy do
    enable :read_note
    enable :admin_note
  end
end
