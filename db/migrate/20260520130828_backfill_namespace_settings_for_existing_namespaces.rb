# frozen_string_literal: true

class BackfillNamespaceSettingsForExistingNamespaces < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      INSERT INTO namespace_settings (namespace_id, created_at, updated_at)
      SELECT id, NOW(), NOW()
      FROM namespaces
      WHERE id NOT IN (SELECT namespace_id FROM namespace_settings)
    SQL
  end

  def down
    # no-op: removing backfilled settings would risk deleting user-modified settings
  end
end
