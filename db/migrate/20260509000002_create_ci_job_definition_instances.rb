class CreateCiJobDefinitionInstances < ActiveRecord::Migration[8.0]
  def change
    create_table :ci_job_definition_instances do |t|
      t.bigint :project_id, null: false
      t.bigint :job_id, null: false
      t.bigint :job_definition_id, null: false
    end

    add_index :ci_job_definition_instances, :job_id, unique: true
    add_index :ci_job_definition_instances, :job_definition_id
  end
end
