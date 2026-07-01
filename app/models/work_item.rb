# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class WorkItem < ApplicationRecord
  include AtomicInternalId
  include Noteable
  include Issuable
  include Participable
  include Mentionable
  include Referable
  include WorkItems::HasState
  include WorkItems::HasWorkflows
  include WorkItems::HasLabels
  include WorkItems::HasParent
  include HasDescription
  include IidRoutes
  include Activities::Trackable
  include Linkable

  belongs_to :author, class_name: 'User'
  belongs_to :updated_by, class_name: 'User', optional: true
  belongs_to :closed_by, class_name: 'User', optional: true
  belongs_to :namespace
  has_one :project, through: :namespace
  has_many :work_item_assignees, dependent: :destroy
  has_many :assignees, class_name: 'User', through: :work_item_assignees

  def assignee_ids=(ids)
    @previous_assignee_ids ||= work_item_assignees.pluck(:assignee_id).sort if persisted?
    super
  end
  has_many :label_links, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_links

  def label_ids=(ids)
    @prev_activity_label_ids ||= LabelLink.where(labelable: self).pluck(:label_id).sort if persisted?
    super
  end

  attr_mentionable :description

  validates :title, presence: true
  validates :confidential, inclusion: { in: [true, false] }
  validates :type, presence: true, inclusion: { in: %w[Issue Epic] }

  has_internal_id :iid, scope: :namespace

  scope :confidential, -> { where(confidential: true) }
  scope :public_only, -> { where(confidential: false) }
  scope :with_state, ->(name) { where(state_id: name) }
  scope :closed, -> { where(state_id: :closed) }
  scope :open, -> { where(state_id: :opened) }
  scope :with_assignee, ->(user_id) { joins(:assignees).where(users: { id: user_id }) }
  scope :with_label_ids, ->(label_ids) do
    if label_ids.blank?
      all
    else
      label_link_ids = LabelLink.joins(:label)
                                .where(labels: { id: label_ids }, labelable_type: 'WorkItem')
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
       WHERE label_links.labelable_id = work_items.id
         AND label_links.labelable_type = 'WorkItem'
         AND labels.title ILIKE ?",
      "#{sanitize_sql_like(scope_name)}::%"
    ])
    order(Arel.sql("(#{rank_subquery}) IS NULL"), Arel.sql("(#{rank_subquery}) #{dir}"))
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[title description state_id author_id created_at updated_at iid]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[author updated_by closed_by namespace labels assignees]
  end

  def current_assignee_ids_for_activity
    WorkItemAssignee.where(work_item_id: id).pluck(:assignee_id).sort
  end

  def custom_notification_target_name
    'work_item'
  end

  def clear_closure_reason_references; end

  def assignee_ids
    assignees.pluck(:id)
  end

  def self.reference_prefix
    '#' # Default for issues
  end

  # `from` argument can be a Namespace or Project.
  def to_reference(from = nil, full: false, absolute_path: false)
    reference = "#{self.class.reference_prefix}#{iid}"

    "#{namespace.to_reference_base(from, full: full, absolute_path: absolute_path)}#{reference}"
  end

  # Override from Noteable concern
  def discussions_resolvable?
    true
  end

  def has_widget?(widget)
    case widget
    when :notes
      true
    else
      false
    end
  end

  def epic?
    type == 'Epic'
  end

  alias_method :epic_work_item?, :epic?

  def issue?
    type == 'Issue'
  end

  def hidden?
    author&.banned?
  end

end
