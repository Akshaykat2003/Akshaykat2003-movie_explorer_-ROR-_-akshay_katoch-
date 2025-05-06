ActiveAdmin.register Subscription do
  permit_params :user_id, :plan, :status, :payment_id, :expiry_date

  index do
    selectable_column
    id_column
    column :user
    column :plan
    column :status
    column :expired do |subscription|
      subscription.expired? ? 'Yes' : 'No'
    end
    column :active do |subscription|
      subscription.active? ? 'Yes' : 'No'
    end
    column :expiry_date
    column :created_at
    column :updated_at
    actions
  end

  filter :user
  filter :plan, as: :select, collection: Subscription.plans.keys.map { |plan| [plan.capitalize, plan] }
  filter :status, as: :select, collection: Subscription.statuses.keys.map { |status| [status.capitalize, status] }
  filter :created_at

  show do
    attributes_table do
      row :user
      row :plan
      row :status
      row :expired do |subscription|
        subscription.expired? ? 'Yes' : 'No'
      end
      row :active do |subscription|
        subscription.active? ? 'Yes' : 'No'
      end
      row :payment_id
      row :expiry_date
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  form do |f|
    f.inputs 'Subscription Details' do
      f.input :user
      f.input :plan, as: :select, collection: Subscription.plans.keys.map { |plan| [plan.capitalize, plan] }
      f.input :status, as: :select, collection: Subscription.statuses.keys.map { |status| [status.capitalize, status] }
      f.input :payment_id, hint: 'Required for Gold and Platinum plans, optional for Basic'
      f.input :expiry_date, as: :datepicker
    end
    f.actions
  end

  member_action :activate, method: :put do
    subscription = Subscription.find(params[:id])
    if subscription.activate!
      redirect_to admin_subscription_path(subscription), notice: "Subscription activated!"
    else
      redirect_to admin_subscription_path(subscription), alert: "Activation failed!"
    end
  end

  member_action :deactivate, method: :put do
    subscription = Subscription.find(params[:id])
    if subscription.deactivate!
      redirect_to admin_subscription_path(subscription), notice: "Subscription deactivated!"
    else
      redirect_to admin_subscription_path(subscription), alert: "Deactivation failed!"
    end
  end

  member_action :cancel, method: :put do
    subscription = Subscription.find(params[:id])
    if subscription.cancel!
      redirect_to admin_subscription_path(subscription), notice: "Subscription cancelled!"
    else
      redirect_to admin_subscription_path(subscription), alert: "Cancellation failed!"
    end
  end

  member_action :upgrade_plan, method: :put do
    subscription = Subscription.find(params[:id])
    new_plan = params[:new_plan]
    if subscription.upgrade_plan(new_plan)
      redirect_to admin_subscription_path(subscription), notice: "Subscription plan upgraded to #{new_plan.capitalize}!"
    else
      redirect_to admin_subscription_path(subscription), alert: "Failed to upgrade plan!"
    end
  end

  member_action :downgrade_plan, method: :put do
    subscription = Subscription.find(params[:id])
    new_plan = params[:new_plan]
    if subscription.downgrade_plan(new_plan)
      redirect_to admin_subscription_path(subscription), notice: "Subscription plan downgraded to #{new_plan.capitalize}!"
    else
      redirect_to admin_subscription_path(subscription), alert: "Failed to downgrade plan!"
    end
  end

  action_item :activate, only: :show do
    if resource.status != 'active'
      link_to 'Activate Subscription', activate_admin_subscription_path(resource), method: :put
    end
  end

  action_item :deactivate, only: :show do
    if resource.status != 'inactive'
      link_to 'Deactivate Subscription', deactivate_admin_subscription_path(resource), method: :put
    end
  end

  action_item :cancel, only: :show do
    if resource.status != 'cancelled'
      link_to 'Cancel Subscription', cancel_admin_subscription_path(resource), method: :put
    end
  end

  action_item :upgrade_to_gold, only: :show do
    if resource.plan != 'gold'
      link_to 'Upgrade to Gold', upgrade_plan_admin_subscription_path(resource, new_plan: 'gold'), method: :put
    end
  end

  action_item :upgrade_to_platinum, only: :show do
    if resource.plan != 'platinum'
      link_to 'Upgrade to Platinum', upgrade_plan_admin_subscription_path(resource, new_plan: 'platinum'), method: :put
    end
  end

  action_item :downgrade_to_basic, only: :show do
    if resource.plan != 'basic'
      link_to 'Downgrade to Basic', downgrade_plan_admin_subscription_path(resource, new_plan: 'basic'), method: :put
    end
  end

  action_item :downgrade_to_gold, only: :show do
    if resource.plan == 'platinum'
      link_to 'Downgrade to Gold', downgrade_plan_admin_subscription_path(resource, new_plan: 'gold'), method: :put
    end
  end
end