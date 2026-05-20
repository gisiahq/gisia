# frozen_string_literal: true

class AddRemoveSourceBranchAfterMergeToNamespaceSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :namespace_settings, :remove_source_branch_after_merge, :boolean, default: true, null: false
  end
end
