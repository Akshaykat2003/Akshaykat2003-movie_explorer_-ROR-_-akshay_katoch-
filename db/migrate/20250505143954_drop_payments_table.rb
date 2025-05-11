class DropPaymentsTable < ActiveRecord::Migration[7.1]
  def change
    if table_exists?(:payments)
      drop_table :payments
    end
  end

end
