# frozen_string_literal: true

class CreateCiDeletedObjects < ActiveRecord::Migration[8.0]
  def change
    create_table :ci_deleted_objects do |t|
      t.integer :file_store, limit: 2, null: false, default: 1
      t.datetime :pick_up_at, null: false, default: -> { 'NOW()' }
      t.text :store_dir, null: false
      t.text :file, null: false
      t.bigint :project_id, null: false
      t.datetime :created_at, null: false, default: -> { 'NOW()' }
    end

    add_index :ci_deleted_objects, :pick_up_at
    add_index :ci_deleted_objects, :project_id
  end
end
