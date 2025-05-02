ActiveAdmin.register Subscription do
  # Permit the required parameters for the Subscription model
  permit_params :user_id, :plan, :status, :payment_id, :expiry_date

  # Customize the index page
  index do
    selectable_column
    id_column
    column :user
    column :plan
    column :status
    column :expiry_date
    column :created_at
    column :updated_at
    actions
  end

  # Filter by plan, status, and user
  filter :user
  filter :plan, as: :select, collection: Subscription.plans.keys.map { |plan| [plan.capitalize, plan] }
  filter :status, as: :select, collection: Subscription.statuses.keys.map { |status| [status.capitalize, status] }
  filter :created_at

  # Show page customization
  show do
    attributes_table do
      row :user
      row :plan
      row :status
      row :payment_id
      row :expiry_date
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  # Form page customization
  form do |f|
    f.inputs 'Subscription Details' do
      f.input :user
      f.input :plan, as: :select, collection: Subscription.plans.keys.map { |plan| [plan.capitalize, plan] }
      f.input :status, as: :select, collection: Subscription.statuses.keys.map { |status| [status.capitalize, status] }
      f.input :payment_id
      f.input :expiry_date, as: :datepicker
    end
    f.actions
  end

  # Custom Action to handle activation/deactivation
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

  # Add custom actions to the index page
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
end
