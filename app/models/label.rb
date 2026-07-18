# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Label < ApplicationRecord
  belongs_to :namespace
  has_many :label_links, dependent: :destroy
  has_many :work_items, through: :label_links, source: :labelable, source_type: 'WorkItem'
  has_many :merge_requests, through: :label_links, source: :labelable, source_type: 'MergeRequest'

  validates :title, presence: true
  validates :color, presence: true
  validates :namespace_id, presence: true
  validate :title_must_not_exist_at_group_level, if: -> { title_changed? && namespace&.project_namespace? }

  scope :search_by_title, ->(keyword) { keyword.present? ? where('LOWER(title) LIKE ?', "%#{keyword.downcase}%") : none }
  scope :with_scopes, ->(prefixes) do
    return none if prefixes.blank?

    prefixes = Array(prefixes)
    conditions = prefixes.map { |prefix| "title LIKE ?" }.join(' OR ')
    values = prefixes.map { |prefix| "#{prefix}%" }
    where(conditions, *values)
  end

  def self.ransackable_attributes(_auth_object = nil)
    ['title']
  end

  def self.ransackable_associations(_auth_object = nil)
    ['namespace']
  end

  def preloaded_parent_container
    namespace.project
  end

  private

  def title_must_not_exist_at_group_level
    ancestor_ids = namespace.lineage_ids - [namespace.id]
    return if ancestor_ids.empty?
    return unless Label.where(namespace_id: ancestor_ids, title: title).exists?

    errors.add(:title, 'already exists at the group level')
  end
end
