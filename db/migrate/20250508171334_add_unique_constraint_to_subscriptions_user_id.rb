class AddUniqueConstraintToSubscriptionsUserId < ActiveRecord::Migration[7.1]
  def change
    # Remove duplicate subscriptions, keeping the most recent one
    reversible do |dir|
      dir.up do
        # This step has already run, but it's idempotent, so it’s safe to keep
        execute <<-SQL
          DELETE FROM subscriptions
          WHERE id IN (
            SELECT id
            FROM (
              SELECT id,
                     ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC) as row_num
              FROM subscriptions
            ) t
            WHERE row_num > 1
          )
        SQL
      end
    end

    # Remove the existing non-unique index
    remove_index :subscriptions, name: "index_subscriptions_on_user_id"

    # Add a new unique index
    add_index :subscriptions, :user_id, unique: true, name: "index_subscriptions_on_user_id"
  end
end
