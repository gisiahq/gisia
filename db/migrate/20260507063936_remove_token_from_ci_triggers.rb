class RemoveTokenFromCiTriggers < ActiveRecord::Migration[8.0]
  def up
    remove_column :ci_triggers, :token, if_exists: true
  end

  def down
    add_column :ci_triggers, :token, :string, if_not_exists: true
    add_index :ci_triggers, :token, unique: true, if_not_exists: true
  end
end
