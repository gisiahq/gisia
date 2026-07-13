class AddCommitIdToReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :reviews, :commit_id, :string
  end
end
