class AddNotificationFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notifications_enabled, :boolean, default: true
    add_column :users, :device_token, :string
    add_index :users, :device_token, unique: true
  end
end
