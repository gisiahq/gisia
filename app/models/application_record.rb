# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

class ApplicationRecord < ActiveRecord::Base
  include DatabaseReflection
  include LegacyBulkInsert
  include DisablesSti
  include Transactions
  include IgnorableColumns

  primary_abstract_class

  alias_method :reset, :reload

  class << self
    # It is strongly suggested use the `.ids` method instead.
    #
    #     User.ids # => returns all the user IDs
    #     User.where(...).ids # => returns the IDs of records matching the where clause.
    #
    alias_method :pluck_primary_key, :ids
  end

  # Connect to main database explicitly (GitLab FOSS style)
  connects_to database: { writing: :main, reading: :main }

  def self.safe_find_or_create_by!(*args, &block)
    safe_find_or_create_by(*args, &block).tap do |record|
      raise ActiveRecord::RecordNotFound unless record.present?

      record.validate! unless record.persisted?
    end
  end

  def self.safe_find_or_create_by(*args, &block)
    record = find_by(*args)
    return record if record.present?

    # We need to use `all.create` to make this implementation follow `find_or_create_by` which delegates this in
    # https://github.com/rails/rails/blob/v6.1.3.2/activerecord/lib/active_record/querying.rb#L22
    #
    # When calling this method on an association, just calling `self.create` would call `ActiveRecord::Persistence.create`
    # and that skips some code that adds the newly created record to the association.
    transaction(requires_new: true) { all.create(*args, &block) }
  rescue ActiveRecord::RecordNotUnique
    find_by(*args)
  end

  def self.without_order
    reorder(nil)
  end

  def self.id_in(ids)
    where(id: ids)
  end

  def self.primary_key_in(values)
    where(primary_key => values)
  end

  def self.id_not_in(ids)
    where.not(id: ids)
  end

  def self.cached_column_list
    column_names.map { |column_name| arel_table[column_name] }
  end

  def self.default_select_columns
    if ignored_columns.any?
      cached_column_list
    else
      arel_table[Arel.star]
    end
  end

  def self.underscore
    @underscore ||= to_s.underscore
  end

  def self.where_exists(query)
    where('EXISTS (?)', query.select(1))
  end

  def self.where_not_exists(query)
    where('NOT EXISTS (?)', query.select(1))
  end

  def self.nullable_column?(column_name)
    columns.find { |column| column.name == column_name }.null &&
      !not_null_check?(column_name)
  end

  def to_ability_name
    model_name.element
  end

  def create_or_load_association(association_name)
    association(association_name).create unless association(association_name).loaded?
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    association(association_name).reader
  end
end
