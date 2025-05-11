class AssignDefaultSubscriptionsToExistingUsers < ActiveRecord::Migration[7.1]
  def up
    User.where.missing(:subscription).find_each do |user|
      Subscription.create!(
        user: user,
        plan: 'basic',
        status: 'active',
        created_at: Time.current,
        updated_at: Time.current
      )
      Rails.logger.info("Created default basic subscription for user #{user.id}")
    end
  end

  def down
    # Optionally, remove the subscriptions if rolling back
    Subscription.where(plan: 'basic', status: 'active').destroy_all
  end
end
