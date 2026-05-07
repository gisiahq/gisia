class RemoveShardingKeyIdAndTokenFromCiRunners < ActiveRecord::Migration[8.0]
  def up
    remove_column :ci_runners, :sharding_key_id, if_exists: true
    remove_column :ci_runners, :token, if_exists: true
  end

  def down
    add_column :ci_runners, :sharding_key_id, :bigint, if_not_exists: true
    add_column :ci_runners, :token, :text, if_not_exists: true

    add_index :ci_runners, :sharding_key_id, if_not_exists: true
    add_index :ci_runners, [:token, :runner_type], unique: true, where: "token IS NOT NULL", if_not_exists: true
  end
end
