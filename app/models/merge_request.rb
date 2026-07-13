# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class MergeRequest < ApplicationRecord
  include AtomicInternalId
  include MergeRequests::Status
  include MergeRequests::MergeStatus
  include Issuable
  include Noteable
  include Participable
  include Mentionable

  include Diffable
  include HasDescription
  include RefComparable
  include ManualInverseAssociation
  include MergeRequests::ReloadDiffs
  include MergeRequests::Pipelines
  include MergeRequests::Variables
  include IidRoutes
  include Activities::Trackable
  include Linkable

  attr_accessor :closing_user

  MERGE_LEASE_TIMEOUT = 15.minutes.to_i

  attr_mentionable :description

  belongs_to :target_project, class_name: 'Project'
  belongs_to :source_project, class_name: 'Project'
  belongs_to :merge_user, class_name: 'User', optional: true
  belongs_to :author, class_name: 'User'

  has_many :merge_request_assignees, dependent: :destroy
  has_many :assignees, through: :merge_request_assignees, source: :assignee

  has_many :merge_request_reviewers, dependent: :destroy
  has_many :reviewers, class_name: 'User', through: :merge_request_reviewers, source: :reviewer

  has_many :reviews, inverse_of: :merge_request, dependent: :destroy
  has_many :draft_notes, inverse_of: :merge_request, dependent: :delete_all
  has_many :reviewed_by_users, -> { distinct }, through: :reviews, source: :author

  has_one :metrics, class_name: 'MergeRequest::Metrics', inverse_of: :merge_request, autosave: true

  has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy
  has_many :activities, class_name: 'MergeRequestActivity', foreign_key: :trackable_id, dependent: :destroy
  has_many :diff_notes, -> { where(type: 'DiffNote') }, as: :noteable, class_name: 'DiffNote', dependent: :destroy

  has_many :label_links, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_links

  def label_ids=(ids)
    @prev_activity_label_ids ||= LabelLink.where(labelable: self).pluck(:label_id).sort if persisted?
    super
  end

  before_update :capture_previous_reviewer_ids

  after_update :clear_memoized_shas
  after_save :keep_around_commit, unless: :importing?
  after_commit :ensure_metrics!, on: [:create, :update], unless: :importing?

  validates :source_branch, presence: true
  validates :target_project, presence: true
  validates :target_branch, presence: true
  validate :validate_branches

  has_internal_id :iid, scope: :target_project, track_if: -> { !importing? },
    init: ->(mr, scope) do
      if mr
        mr.target_project&.merge_requests&.maximum(:iid)
      elsif scope[:project]
        where(target_project: scope[:project]).maximum(:iid)
      end
    end

  alias_method :project, :target_project
  alias_attribute :project_id, :target_project_id

  scope :by_source_or_target_branch, ->(branch_name) do
    where('source_branch = :branch OR target_branch = :branch', branch: branch_name)
  end

  scope :preload_project_and_latest_diff, -> { preload(:source_project, :latest_merge_request_diff) }
  scope :from_fork, -> { where('source_project_id <> target_project_id') }

  scope :with_assignee, ->(user_id) { joins(:assignees).where(users: { id: user_id }) }
  scope :with_reviewer, ->(user_id) { joins(:reviewers).where(users: { id: user_id }) }

  scope :with_label_ids, ->(label_ids) do
    if label_ids.blank?
      all
    else
      label_link_ids = LabelLink.joins(:label)
                                .where(labels: { id: label_ids }, labelable_type: 'MergeRequest')
                                .group('labelable_id')
                                .having('COUNT(*) = ?', label_ids.size)
                                .pluck('labelable_id')
      where(id: label_link_ids)
    end
  end

  # orders by the `rank` of the item's label within the given scope
  # (e.g. scope_name "Priority" matches labels titled "Priority::*").
  # items without a label in that scope sort last.
  scope :order_by_label_rank, ->(scope_name, direction) do
    dir = direction == :desc ? 'DESC' : 'ASC'
    rank_subquery = sanitize_sql_array([
      "SELECT MIN(labels.rank) FROM label_links
       INNER JOIN labels ON labels.id = label_links.label_id
       WHERE label_links.labelable_id = merge_requests.id
         AND label_links.labelable_type = 'MergeRequest'
         AND labels.title ILIKE ?",
      "#{sanitize_sql_like(scope_name)}::%"
    ])
    order(Arel.sql("(#{rank_subquery}) IS NULL"), Arel.sql("(#{rank_subquery}) #{dir}"))
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status author_id title description source_branch target_branch]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[assignees reviewers labels]
  end

  def relink_label_ids(extra_label_ids)
    return if extra_label_ids.blank?

    old_label_ids = label_links.pluck(:label_id)
    new_labels = Label.where(id: extra_label_ids, namespace_id: project.namespace_id)
    new_scopes = new_labels.select { |l| l.title.include?('::') }.group_by { |l| l.title.split('::').first }.keys

    ids_to_remove = []
    if old_label_ids.present? && new_scopes.present?
      old_labels = Label.where(id: old_label_ids, namespace_id: project.namespace_id)
      new_scopes.each do |scope|
        ids_to_remove.concat(old_labels.select { |l| l.title.start_with?("#{scope}::") }.map(&:id))
      end
    end

    self.label_ids = (old_label_ids | extra_label_ids) - ids_to_remove
  end

  def clear_memoized_shas
    @target_branch_sha = @source_branch_sha = nil

    clear_memoization(:source_branch_head)
    clear_memoization(:target_branch_head)
  end

  def keep_around_commit
    project.repository.keep_around(merge_commit_sha, source: self.class.name)
  end

  def self.merge_request_ref?(ref)
    ref.start_with?("refs/#{Repository::REF_MERGE_REQUEST}/")
  end

  def self.reference_prefix
    '!'
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{project.to_reference_base(from, full: full)}#{reference}"
  end

  def commits(limit: nil, load_from_gitaly: false, page: nil)
    if use_live_comparison?
      commits_arr = if compare_commits
                      reversed_commits = compare_commits.reverse
                      limit ? reversed_commits.take(limit) : reversed_commits
                    else
                      []
                    end

      CommitCollection.new(source_project, commits_arr, source_branch)
    else
      diff_commits = merge_request_diff.merge_request_diff_commits.limit(limit)
      commits_list = diff_commits.with_users
        .map { |commit| Commit.from_hash(commit.to_hash, source_project) }

      CommitCollection.new(source_project, commits_list, source_branch)
    end
  end

  def recent_commits(limit: MergeRequestDiff::COMMITS_SAFE_SIZE, load_from_gitaly: false, page: nil)
    commits(limit: limit, load_from_gitaly: load_from_gitaly, page: page)
  end

  def commits_count
    if use_live_comparison?
      compare_commits&.size || 0
    elsif merge_request_diff.persisted?
      merge_request_diff.commits_count
    else
      0
    end
  end

  def commit_shas(limit: nil)
    shas =
      if compare_commits
        compare_commits.to_a.reverse.map(&:sha)
      else
        Array(diff_head_sha)
      end

    limit ? shas.take(limit) : shas
  end

  def diffs(diff_options = {})
    if use_live_comparison?
      compare.diffs(diff_options.merge(expanded: true))
    else
      merge_request_diff.diffs(diff_options)
    end
  end

  MAX_RECENT_DIFF_HEAD_SHAS = 100

  def recent_diff_head_shas(limit = MAX_RECENT_DIFF_HEAD_SHAS)
    # see MergeRequestDiff.recent
    if merge_request_diffs.loaded?
      return merge_request_diffs.to_a.sort_by(&:id).reverse.first(limit).pluck(:head_commit_sha)
    end

    merge_request_diffs.recent(limit).pluck(:head_commit_sha)
  end

  def importing?
    false
  end

  def for_fork?
    target_project != source_project
  end

  def for_same_project?
    target_project == source_project
  end

  # Override from Noteable concern
  def discussions_resolvable?
    true
  end

  def project
    target_project
  end

  def reached_versions_limit?
    false
  end

  def reached_diff_commits_limit?
    false
  end

  def default_merge_commit_message(user: nil)
    url = Gitlab::Routing.url_helpers.namespace_project_merge_request_url(
      target_project.namespace.parent.full_path,
      target_project.namespace.path,
      self
    )
    "#{title}\n\nMerge Request: #{url}"
  end

  def update_and_mark_in_progress_merge_commit_sha(commit_id)
    update_column(:in_progress_merge_commit_sha, commit_id)
  end

  def in_locked_state
    lock_mr
    yield
  ensure
    unlock_mr if locked?
  end

  def merged_at
    metrics&.merged_at
  end

  def merge_exclusive_lease
    lease_key = "merge_requests_merge_service:#{id}"
    Gitlab::ExclusiveLease.new(lease_key, timeout: MERGE_LEASE_TIMEOUT)
  end

  def existing_mrs_targeting_same_branch
    similar_mrs = target_project
      .merge_requests
      .where(source_branch: source_branch, target_branch: target_branch)
      .where(source_project: source_project)
      .opened

    similar_mrs = similar_mrs.id_not_in(id) if persisted?

    similar_mrs
  end

  def assignee_ids=(ids)
    @previous_assignee_ids ||= MergeRequestAssignee.where(merge_request_id: id).pluck(:user_id).sort if persisted?
    super
  end

  def reviewer_ids=(ids)
    @previous_reviewer_ids ||= MergeRequestReviewer.where(merge_request_id: id).pluck(:user_id).sort if persisted?
    super
  end

  private

  def current_assignee_ids_for_activity
    MergeRequestAssignee.where(merge_request_id: id).pluck(:user_id).sort
  end

  def current_reviewer_ids_for_activity
    MergeRequestReviewer.where(merge_request_id: id).pluck(:user_id).sort
  end

  def capture_previous_assignee_ids
    @previous_assignee_ids ||= MergeRequestAssignee.where(merge_request_id: id).pluck(:user_id).sort
  end

  def capture_previous_reviewer_ids
    @previous_reviewer_ids ||= MergeRequestReviewer.where(merge_request_id: id).pluck(:user_id).sort
  end

  def notify_on_create
    return unless notification_author

    NotificationService.new.new_merge_request(self, notification_author)
  end

  def notify_on_update
    return unless notification_author

    if saved_change_to_status?
      if closed?
        NotificationService.new.close_mr(self, notification_author)
      else
        NotificationService.new.reopen_mr(self, notification_author)
      end
    end

    return unless @previous_assignee_ids && assignees.map(&:id).sort != @previous_assignee_ids

    NotificationService.new.reassigned_merge_request(self, notification_author, User.where(id: @previous_assignee_ids))
  end

  def use_live_comparison?
    opened? || merge_request_diff.empty?
  end

  def validate_branches
    return unless target_project && source_project

    if target_project == source_project && target_branch == source_branch
      errors.add :branch_conflict, "You can't use same project/branch for source and target"
      return
    end

    if opened?
      conflicting_mr = existing_mrs_targeting_same_branch.first
      return unless conflicting_mr

      errors.add(
        :validate_branches,
        "Another open merge request already exists for this source branch"
      )
    end
  end

  def ensure_metrics!
    MergeRequest::Metrics.record!(self)
  end
end
