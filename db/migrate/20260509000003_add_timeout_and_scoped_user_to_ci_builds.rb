# frozen_string_literal: true

class AddTimeoutAndScopedUserToCiBuilds < ActiveRecord::Migration[7.1]
  def change
    add_column :ci_builds, :timeout, :integer
    add_column :ci_builds, :timeout_source, :integer
    add_column :ci_builds, :scoped_user_id, :bigint
  end
end
