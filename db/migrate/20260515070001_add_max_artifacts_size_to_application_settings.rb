class AddMaxArtifactsSizeToApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :application_settings, :max_artifacts_size, :integer, null: false, default: 100
  end
end
