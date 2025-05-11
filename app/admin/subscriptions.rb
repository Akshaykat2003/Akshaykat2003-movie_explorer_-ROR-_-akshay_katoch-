ActiveAdmin.register Subscription do
  permit_params :plan, :status


  index do
    selectable_column
    id_column
    column :user
    column :plan
    column :status
    column :created_at
    column :updated_at
    column :expiry_date
    column :session_id
    column :session_expires_at
    actions
  end

  filter :user, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }
  filter :plan, as: :select, collection: Subscription.plans.keys
  filter :status, as: :select, collection: Subscription.statuses.keys
  filter :session_id
  filter :session_expires_at
  filter :created_at
  filter :updated_at
  filter :expiry_date

 
  show do
    attributes_table do
      row :id
      row :user
      row :plan
      row :status
      row :created_at
      row :updated_at
      row :expiry_date
      row :session_id
      row :session_expires_at
    end
  end


  form do |f|
    f.inputs "Subscription Details" do
      f.input :user, as: :select, collection: User.all.map { |u| [u.email, u.id] }, input_html: { disabled: true }
      f.input :plan, as: :select, collection: Subscription.plans.keys
      f.input :status, as: :select, collection: Subscription.statuses.keys
      f.input :expiry_date, as: :datetime_picker
  
      f.input :session_id, input_html: { disabled: true }
      f.input :session_expires_at, as: :datetime_picker, input_html: { disabled: true }
    end
    f.actions
  end
end