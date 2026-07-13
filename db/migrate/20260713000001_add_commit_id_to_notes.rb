class AddCommitIdToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :commit_id, :string
  end
end
