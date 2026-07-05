# frozen_string_literal: true

class AddSharedRunnersEnabledToNamespaceSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :namespace_settings, :shared_runners_enabled, :boolean, default: true, null: false
  end
end
