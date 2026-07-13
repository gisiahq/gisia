class CreateDraftNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :draft_notes do |t|
      t.bigint :merge_request_id, null: false
      t.bigint :author_id, null: false
      t.bigint :namespace_id, null: false
      t.text :note, null: false
      t.string :note_type
      t.text :position
      t.text :original_position
      t.text :change_position
      t.string :line_code
      t.string :commit_id
      t.bigint :discussion_id
      t.boolean :resolve_discussion, null: false, default: false
      t.boolean :internal, null: false, default: false

      t.timestamps
    end

    add_index :draft_notes, %i[merge_request_id author_id]
  end
end
