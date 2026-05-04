class ChangeSquashEnabledDefaultInNamespaceSettings < ActiveRecord::Migration[8.0]
  def change
    change_column_default :namespace_settings, :squash_enabled, from: false, to: true
  end
end
