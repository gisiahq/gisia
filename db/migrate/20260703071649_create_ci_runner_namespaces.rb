# frozen_string_literal: true

class CreateCiRunnerNamespaces < ActiveRecord::Migration[8.0]
  def change
    create_table :ci_runner_namespaces do |t|
      t.bigint :runner_id, null: false
      t.bigint :namespace_id, null: false
    end

    add_index :ci_runner_namespaces, [:runner_id, :namespace_id], unique: true
    add_index :ci_runner_namespaces, :namespace_id
  end
end
