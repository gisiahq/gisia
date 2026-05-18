# frozen_string_literal: true

class RemoveMobileFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :mobile, :string
  end
end
