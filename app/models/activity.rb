# frozen_string_literal: true

class Activity < ApplicationRecord
  self.primary_key = :id

  enum :action_type, {
    closed: 0,
    reopened: 1,
    note_added: 2,
    label_added: 3,
    label_removed: 4,
    assignee_added: 5,
    assignee_removed: 6,
    title_changed: 7,
    description_changed: 8,
    reviewer_added: 9,
    reviewer_removed: 10,
    item_linked: 11,
    item_unlinked: 12,
    review_added: 13
  }

  belongs_to :trackable, polymorphic: true
  belongs_to :author, class_name: 'User', optional: true
  belongs_to :note, optional: true

  before_validation :cache_details_html, on: :create

  scope :chronological, -> { order(:created_at) }

  def self.partition_model_for(trackable_type)
    case trackable_type
    when 'Issue'
      IssueActivity
    when 'MergeRequest'
      MergeRequestActivity
    when 'Epic'
      EpicActivity
    else
      self
    end
  end

  private

  def cache_details_html
    return if details_html.present?

    text = render_text
    self.details_html = ERB::Util.html_escape(text) if text
  end

  public

  def render_text
    resource = trackable_type.underscore.humanize.downcase
    case action_type
    when 'closed'              then "closed this #{resource}"
    when 'reopened'            then "reopened this #{resource}"
    when 'note_added'          then nil
    when 'label_added'         then "added labels #{Label.where(id: details['label_ids']).pluck(:title).join(', ')}"
    when 'label_removed'       then "removed labels #{Label.where(id: details['label_ids']).pluck(:title).join(', ')}"
    when 'assignee_added'      then "assigned to #{User.where(id: details['user_ids']).map { |u| u.name.presence || u.username }.join(', ')}"
    when 'assignee_removed'    then "unassigned #{User.where(id: details['user_ids']).map { |u| u.name.presence || u.username }.join(', ')}"
    when 'reviewer_added'      then "requested review from #{User.where(id: details['user_ids']).map { |u| u.name.presence || u.username }.join(', ')}"
    when 'reviewer_removed'    then "removed reviewer #{User.where(id: details['user_ids']).map { |u| u.name.presence || u.username }.join(', ')}"
    when 'title_changed'       then "changed title from \"#{details['from']}\" to \"#{details['to']}\""
    when 'description_changed' then "changed the description"
    when 'review_added'          then 'submitted a review'
    when 'item_linked', 'item_unlinked'
      target = details['target_type'].constantize.find_by(id: details['target_id'])
      verb = item_linked? ? 'linked' : 'unlinked'
      target ? "#{verb} #{target.to_reference}" : verb
    end
  end
end
