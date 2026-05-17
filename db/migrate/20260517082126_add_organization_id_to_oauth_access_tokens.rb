class AddOrganizationIdToOauthAccessTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :oauth_access_tokens, :organization_id, :bigint, null: false, default: 1
    add_index :oauth_access_tokens, :organization_id
  end
end
