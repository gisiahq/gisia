class AddDefaultTimezoneToUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :timezone, from: nil, to: 'UTC'
  end
end
