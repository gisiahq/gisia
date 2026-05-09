# frozen_string_literal: true

class AddGranularToPersonalAccessTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :personal_access_tokens, :granular, :boolean, default: false, null: false
  end
end
