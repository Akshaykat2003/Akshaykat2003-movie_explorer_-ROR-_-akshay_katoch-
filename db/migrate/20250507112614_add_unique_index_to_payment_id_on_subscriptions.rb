class AddUniqueIndexToPaymentIdOnSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_index :subscriptions, :payment_id, unique: true
  end
end
