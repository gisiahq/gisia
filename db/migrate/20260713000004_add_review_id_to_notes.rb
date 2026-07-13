class AddReviewIdToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :notes, :review_id, :bigint
    add_index :notes, :review_id
  end
end
