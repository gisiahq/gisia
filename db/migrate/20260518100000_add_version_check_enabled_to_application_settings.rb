# frozen_string_literal: true

class AddVersionCheckEnabledToApplicationSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :application_settings, :version_check_enabled, :boolean, null: false, default: true
  end
end
