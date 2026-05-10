class AddImpersonationToPersonalAccessTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :personal_access_tokens, :impersonation, :boolean, default: false, null: false
    add_index :personal_access_tokens, [:user_id, :created_at, :id],
      where: 'impersonation = false',
      name: 'idx_pat_on_user_id_created_at_no_impersonation'
  end
end
