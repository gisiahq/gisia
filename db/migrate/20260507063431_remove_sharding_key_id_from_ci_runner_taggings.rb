class RemoveShardingKeyIdFromCiRunnerTaggings < ActiveRecord::Migration[8.0]
  def up
    remove_column :ci_runner_taggings, :sharding_key_id, if_exists: true
  end

  def down
    add_column :ci_runner_taggings, :sharding_key_id, :bigint, if_not_exists: true
    add_index :ci_runner_taggings, :sharding_key_id, if_not_exists: true
  end
end
