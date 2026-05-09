class CreateCiJobDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :ci_job_definitions do |t|
      t.bigint :project_id, null: false
      t.jsonb :config, null: false, default: {}
      t.text :checksum, null: false
      t.boolean :interruptible
      t.timestamps
    end

    add_index :ci_job_definitions, [:project_id, :checksum], unique: true
    add_index :ci_job_definitions, :checksum
  end
end
