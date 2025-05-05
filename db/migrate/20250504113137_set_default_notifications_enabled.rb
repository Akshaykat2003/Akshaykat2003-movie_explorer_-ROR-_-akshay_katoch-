class SetDefaultNotificationsEnabled < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :notifications_enabled, from: nil, to: true
  
    User.where(notifications_enabled: nil).update_all(notifications_enabled: true)
  end
end
