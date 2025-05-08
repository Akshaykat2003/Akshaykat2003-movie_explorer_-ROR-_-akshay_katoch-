class RemoveUniqueIndexOnDeviceToken < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique index on device_token if it exists
    remove_index :users, :device_token, unique: true, if_exists: true

    # Add a regular index (non-unique) for performance, if desired
    add_index :users, :device_token, if_not_exists: true
  end
end
