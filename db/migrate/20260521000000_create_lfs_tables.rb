# frozen_string_literal: true

class CreateLfsTables < ActiveRecord::Migration[7.0]
  def change
    create_table :lfs_objects do |t|
      t.string :oid, null: false
      t.bigint :size, null: false
      t.string :file
      t.integer :file_store, default: 1, null: false
      t.timestamps
    end

    add_index :lfs_objects, :oid, unique: true
    add_index :lfs_objects, :file
    add_index :lfs_objects, :file_store

    create_table :lfs_objects_projects do |t|
      t.bigint :lfs_object_id, null: false
      t.bigint :project_id, null: false
      t.column :repository_type, :smallint
      t.text :oid
      t.timestamps
    end

    add_index :lfs_objects_projects, :lfs_object_id
    add_index :lfs_objects_projects, :oid
    add_index :lfs_objects_projects, [:project_id, :lfs_object_id]
    add_index :lfs_objects_projects, [:project_id, :lfs_object_id],
      unique: true,
      where: 'repository_type IS NULL',
      name: 'idx_lfs_objects_projects_null_repo_type'
    add_index :lfs_objects_projects, [:project_id, :lfs_object_id, :repository_type],
      unique: true,
      where: 'repository_type IS NOT NULL',
      name: 'idx_lfs_objects_projects_with_repo_type'

    create_table :lfs_file_locks do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
      t.string :path, limit: 511
      t.datetime :created_at, null: false
    end

    add_index :lfs_file_locks, [:project_id, :path], unique: true
    add_index :lfs_file_locks, :user_id
  end
end
