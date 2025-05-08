class RemovePaymentIdFromSubscriptions < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscriptions, :payment_id, :string
  end
end
