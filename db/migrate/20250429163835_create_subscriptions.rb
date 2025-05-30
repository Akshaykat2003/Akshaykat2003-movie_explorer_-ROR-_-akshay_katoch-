class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :plan
      t.string :status
      t.string :payment_id

      t.timestamps
    end
  end
end
