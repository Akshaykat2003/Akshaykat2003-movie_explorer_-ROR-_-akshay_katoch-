class RemoveStripeCustomerIdFromUsers < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:users, :stripe_customer_id)
      remove_column :users, :stripe_customer_id, :string
    end
  end
end
