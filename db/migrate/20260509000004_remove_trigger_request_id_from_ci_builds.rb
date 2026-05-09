# frozen_string_literal: true

class RemoveTriggerRequestIdFromCiBuilds < ActiveRecord::Migration[7.1]
  def change
    remove_column :ci_builds, :trigger_request_id, :bigint
  end
end
