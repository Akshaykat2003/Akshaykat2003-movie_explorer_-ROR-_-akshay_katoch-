class AddExpiryDateToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :expiry_date, :datetime
  end
end
