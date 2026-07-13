# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

module Diffable
  extend ActiveSupport::Concern
  include ManualInverseAssociation
  include Gitlab::Utils::StrongMemoize

  included do
    has_many :merge_request_diffs,
      -> { regular }, inverse_of: :merge_request
    has_one :merge_request_diff,
      -> { regular.order('merge_request_diffs.id DESC') }, inverse_of: :merge_request

    belongs_to :latest_merge_request_diff, class_name: 'MergeRequestDiff', optional: true
    manual_inverse_association :latest_merge_request_diff, :merge_request

    after_create :ensure_merge_request_diff, unless: :skip_ensure_merge_request_diff

    # Temporary flag to skip merge_request_diff creation on create.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100390
    attr_accessor :skip_ensure_merge_request_diff
  end

  def diff_refs
    if importing? || persisted?
      merge_request_diff.diff_refs
    else
      repository_diff_refs
    end
  end

  def has_complete_diff_refs?
    diff_refs && diff_refs.complete?
  end

  def diff_base_commit
    branch_merge_base_commit
  end

  def diff_start_commit
    target_branch_head
  end

  def diff_head_commit
    source_branch_head
  end

  def diff_start_sha
    target_branch_head.try(:sha)
  end

  def diff_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def diff_head_sha
    source_branch_head.try(:sha)
  end

  def branch_merge_base_sha
    branch_merge_base_commit.try(:sha)
  end

  def branch_merge_base_commit
    start_sha = target_branch_sha
    head_sha  = source_branch_sha

    return unless start_sha && head_sha

    target_project.merge_base_commit(start_sha, head_sha)
  end

  def target_branch_sha
    @target_branch_sha || target_branch_head.try(:sha)
  end

  def source_branch_sha
    @source_branch_sha || source_branch_head.try(:sha)
  end

  def source_branch_ref(or_sha: true)
    return @source_branch_sha if @source_branch_sha && or_sha
    return unless source_branch

    Gitlab::Git::BRANCH_REF_PREFIX + source_branch
  end

  def target_branch_ref
    return @target_branch_sha if @target_branch_sha
    return unless target_branch

    Gitlab::Git::BRANCH_REF_PREFIX + target_branch
  end

  def source_branch_head
    strong_memoize(:source_branch_head) do
      source_project.repository.commit(source_branch_ref) if source_project && source_branch_ref
    end
  end

  def target_branch_head
    strong_memoize(:target_branch_head) do
      target_project.repository.commit(target_branch_ref)
    end
  end

  # Instead trying to fetch the
  # persisted diff_refs, this method goes
  # straight to the repository to get the
  # most recent data possible.
  def repository_diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha: branch_merge_base_sha,
      start_sha: target_branch_sha,
      head_sha: source_branch_sha
    )
  end

  def ensure_merge_request_diff
    merge_request_diff.persisted? || create_merge_request_diff
  end

  def create_merge_request_diff(preload_gitaly: false)
    fetch_ref!

    # n+1: https://gitlab.com/gitlab-org/gitlab/-/issues/19377
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      if preload_gitaly
        new_diff = merge_request_diffs.build
        new_diff.preload_gitaly_data
        new_diff.save!
      else
        merge_request_diffs.create!
      end

      reload_merge_request_diff
    end
  end

  def fetch_ref!
    target_project.repository.fetch_source_branch!(source_project.repository, source_branch_ref(or_sha: false),
      ref_path)
  end

  def ref_path
    "refs/#{Repository::REF_MERGE_REQUEST}/#{iid}/head"
  end

  # This is the same as latest_merge_request_diff unless:
  # 1. There are arguments - in which case we might be trying to force-reload.
  # 2. This association is already loaded.
  # 3. The latest diff does not exist.
  # 4. It doesn't have any merge_request_diffs - it returns an empty MergeRequestDiff
  #
  # The second one in particular is important - MergeRequestDiff#merge_request
  # is the inverse of MergeRequest#merge_request_diff, which means it may not be
  # the latest diff, because we could have loaded any diff from this particular
  # MR. If we haven't already loaded a diff, then it's fine to load the latest.
  def merge_request_diff
    fallback = latest_merge_request_diff unless association(:merge_request_diff).loaded?

    fallback || super || MergeRequestDiff.new(merge_request_id: id)
  end

  def find_diff_head_pipeline
    all_pipelines.for_sha_or_source_sha(diff_head_sha).first
  end

  def viewable_diffs
    @viewable_diffs ||= merge_request_diffs.viewable.to_a
  end

  def merge_request_diff_for(diff_refs_or_sha)
    matcher =
      if diff_refs_or_sha.is_a?(Gitlab::Diff::DiffRefs)
        {
          'start_commit_sha' => diff_refs_or_sha.start_sha,
          'head_commit_sha' => diff_refs_or_sha.head_sha,
          'base_commit_sha' => diff_refs_or_sha.base_sha
        }
      else
        { 'head_commit_sha' => diff_refs_or_sha }
      end

    viewable_diffs.find do |diff|
      diff.attributes.slice(*matcher.keys) == matcher
    end
  end

  def version_params_for(diff_refs)
    if (diff = merge_request_diff_for(diff_refs))
      { diff_id: diff.id }
    elsif (diff = merge_request_diff_for(diff_refs.head_sha))
      { diff_id: diff.id, start_sha: diff_refs.start_sha }
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def update_diff_discussion_positions(old_diff_refs:, new_diff_refs:, current_user: nil)
    return unless has_complete_diff_refs?
    return if new_diff_refs == old_diff_refs

    update_draft_note_positions(old_diff_refs, new_diff_refs)

    active_diff_discussions = self.notes.new_diff_notes.discussions.select do |discussion|
      discussion.active?(old_diff_refs)
    end
    return if active_diff_discussions.empty?

    paths = active_diff_discussions.flat_map { |n| n.diff_file.paths }.uniq

    active_discussions_resolved = active_diff_discussions.all?(&:resolved?)

    service = Discussions::UpdateDiffPositionService.new(
      self.project,
      current_user,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: paths
    )

    Gitlab::GitalyClient.allow_n_plus_1_calls do
      active_diff_discussions.each do |discussion|
        service.execute(discussion)
        discussion.clear_memoized_values
      end
    end
  end

  # Pending drafts of all authors are re-traced on push so they stay
  # correctly placed on the new diff until they are published.
  def update_draft_note_positions(old_diff_refs, new_diff_refs)
    active_drafts = draft_notes.select do |draft|
      draft.on_diff? && draft.position.diff_refs == old_diff_refs
    end
    return if active_drafts.empty?

    Gitlab::GitalyClient.allow_n_plus_1_calls do
      active_drafts.each do |draft|
        tracer = Gitlab::Diff::PositionTracer.new(
          project: project,
          old_diff_refs: old_diff_refs,
          new_diff_refs: new_diff_refs,
          paths: draft.position.paths
        )

        result = tracer.trace(draft.position)
        next unless result

        if result[:outdated]
          draft.change_position = result[:position]
        else
          draft.position = result[:position]
        end

        draft.save!(touch: false)
      end
    end
  end
end
