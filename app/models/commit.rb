# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class Commit
  include ::Gitlab::Utils::StrongMemoize
  include Commits::Signaturable

  attr_accessor :raw
  attr_reader :container

  delegate :author_name, :author_email, :message, :tree_entry, :committed_date, :parent, :parent_id, :parent_ids,
    to: :raw

  delegate :repository, to: :container
  delegate :project, to: :repository, allow_nil: true

  DIFF_SAFE_LIMIT_FACTOR = 10
  MIN_SHA_LENGTH = Gitlab::Git::Commit::MIN_SHA_LENGTH
  MAX_SHA_LENGTH = Gitlab::Git::Commit::MAX_SHA_LENGTH
  COMMIT_SHA_PATTERN = Gitlab::Git::Commit::SHA_PATTERN
  WHOLE_WORD_COMMIT_SHA_PATTERN = /\b#{COMMIT_SHA_PATTERN}\b/
  EXACT_COMMIT_SHA_PATTERN = /\A#{COMMIT_SHA_PATTERN}\z/

  DEFAULT_MAX_DIFF_LINES_SETTING = 50_000
  DEFAULT_MAX_DIFF_FILES_SETTING = 1_000
  MAX_DIFF_LINES_SETTING_UPPER_BOUND = 100_000
  MAX_DIFF_FILES_SETTING_UPPER_BOUND = 3_000

  def initialize(raw_commit, container)
    raise 'Nil as raw commit passed' unless raw_commit

    @raw = raw_commit
    @container = container
  end

  def id
    raw.id
  end

  def sha
    id
  end

  def project_id
    project&.id
  end

  def lazy_author
    return nil if author_email.blank?

    User.find_by(email: author_email.downcase)
  end

  def author
    @author ||= lazy_author
  end

  def to_hash
    @raw.to_hash
  end

  def title
    return full_title if full_title.length < 100

    full_title.truncate(81, separator: ' ', omission: '...')
  end

  def full_title
    @full_title ||=
      if message.blank?
        'No commit message'
      else
        message.split(/[\r\n]/, 2).first
      end
  end

  def timestamp
    committed_date.xmlschema
  end

  def hook_attrs(with_changed_files: false)
    {
      id: id,
      message: message,
      title: title,
      timestamp: timestamp,
      url: Gitlab::UrlBuilder.commit_url(self),
      author: {
        name: author_name,
        email: author_email
      }
    }
  end

  def raw_diffs(...)
    raw.diffs(...)
  end

  def diffs(diff_options = {})
    Gitlab::Diff::FileCollection::Commit.new(self, diff_options: diff_options)
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha: parent_id || container.repository.blank_ref,
      head_sha: sha
    )
  end

  def short_id
    @raw.short_id(MIN_SHA_LENGTH)
  end

  class << self
    def valid_hash?(key)
      !!(EXACT_COMMIT_SHA_PATTERN =~ key)
    end

    def decorate(commits, container)
      commits.map do |commit|
        if commit.is_a?(Commit)
          commit
        else
          new(commit, container)
        end
      end
    end

    def from_hash(hash, container)
      raw_commit = Gitlab::Git::Commit.new(container.repository.raw, hash)
      new(raw_commit, container)
    end

    def diff_max_files
      Gitlab::CurrentSettings.diff_max_files
    end

    def diff_max_lines
      Gitlab::CurrentSettings.diff_max_lines
    end

    def max_diff_options
      {
        max_files: diff_max_files,
        max_lines: diff_max_lines
      }
    end

    def diff_safe_max_files
      diff_max_files / DIFF_SAFE_LIMIT_FACTOR
    end

    def diff_safe_max_lines
      diff_max_lines / DIFF_SAFE_LIMIT_FACTOR
    end

    def lazy(container, oid)
      BatchLoader.for({ container: container, oid: oid }).batch do |items, loader|
        items_by_container = items.group_by { |i| i[:container] }

        items_by_container.each do |container, commit_ids|
          oids = commit_ids.map { |i| i[:oid] }

          container.repository.commits_by(oids: oids).each do |commit|
            loader.call({ container: commit.container, oid: commit.id }, commit) if commit
          end
        end
      end
    end
  end
end

