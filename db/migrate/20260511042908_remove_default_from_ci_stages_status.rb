class RemoveDefaultFromCiStagesStatus < ActiveRecord::Migration[8.0]
  def change
    change_column_default :ci_stages, :status, from: 0, to: nil
  end
end
