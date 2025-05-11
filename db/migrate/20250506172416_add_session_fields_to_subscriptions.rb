class AddSessionFieldsToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :session_id, :string
    add_column :subscriptions, :session_expires_at, :datetime
  end
end
