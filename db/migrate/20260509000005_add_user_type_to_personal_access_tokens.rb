# frozen_string_literal: true

class AddUserTypeToPersonalAccessTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :personal_access_tokens, :user_type, :smallint, default: 0
  end
end
