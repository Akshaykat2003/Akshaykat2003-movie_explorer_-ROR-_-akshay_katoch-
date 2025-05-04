ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :password, :mobile_number, :role

 
  filter :first_name
  filter :last_name
  filter :email
  filter :mobile_number
  filter :role

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :mobile_number
    column :role
    actions
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :mobile_number
      f.input :role, as: :select, collection: ['user', 'supervisor'], include_blank: false
      if f.object.new_record?
        f.input :password
      else
        f.input :password, input_html: { autocomplete: "new-password" }, hint: "Leave blank if you don't want to change it"
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :first_name
      row :last_name
      row :email
      row :mobile_number
      row :role
    end
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
      end
      super
    end
  end
end
ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :password, :mobile_number, :role


  filter :first_name
  filter :last_name
  filter :email
  filter :mobile_number
  filter :role

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :mobile_number
    column :role
    actions
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :mobile_number
      f.input :role, as: :select, collection: ['user', 'supervisor'], include_blank: false
      if f.object.new_record?
        f.input :password
      else
        f.input :password, input_html: { autocomplete: "new-password" }, hint: "Leave blank if you don't want to change it"
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :first_name
      row :last_name
      row :email
      row :mobile_number
      row :role
    end
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete(:password)
      end
      super
    end
  end
end
