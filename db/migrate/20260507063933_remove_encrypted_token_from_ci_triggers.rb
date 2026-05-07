class RemoveEncryptedTokenFromCiTriggers < ActiveRecord::Migration[8.0]
  def up
    remove_column :ci_triggers, :encrypted_token, if_exists: true
    remove_column :ci_triggers, :encrypted_token_iv, if_exists: true
  end

  def down
    add_column :ci_triggers, :encrypted_token, :binary, if_not_exists: true
    add_column :ci_triggers, :encrypted_token_iv, :binary, if_not_exists: true
  end
end
