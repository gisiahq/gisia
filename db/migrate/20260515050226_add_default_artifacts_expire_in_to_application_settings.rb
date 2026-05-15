# frozen_string_literal: true

class AddDefaultArtifactsExpireInToApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :application_settings, :default_artifacts_expire_in, :string, null: false, default: '30 days'
  end
end
