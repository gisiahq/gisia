# frozen_string_literal: true

class CreateNamespacePins < ActiveRecord::Migration[8.0]
  def change
    create_table :namespace_pins do |t|
      t.bigint :namespace_id, null: false
      t.bigint :user_id, null: false
      t.string :type, null: false

      t.timestamps
    end

    add_index :namespace_pins, :namespace_id
    add_index :namespace_pins, [:user_id, :type]
    add_index :namespace_pins, [:user_id, :namespace_id], unique: true
  end
end
