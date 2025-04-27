ActiveAdmin.register Movie do
  # Permit these parameters
  permit_params :title, :genre, :release_year, :rating, :director, :duration, :description, :plan, :poster

  # Controller block to handle role-based access
  controller do
    # before_action :authorize_admin_only

    private

    def authorize_admin_only
      unless current_user && current_user.role == 'admin'
        redirect_to admin_dashboard_path, alert: 'You do not have permission to perform this action.'
      end
    end
  end

  # Filters on index page
  filter :title
  filter :genre
  filter :release_year
  filter :rating
  filter :plan, as: :select, collection: Movie.plans.keys.map { |plan| [plan.capitalize, plan] }

  # Index page
  index do
    selectable_column
    id_column
    column :title
    column :genre
    column :release_year
    column :rating
    column :director
    column :duration
    column :description
    column :plan
    actions
  end

  # Show page
  show do
    attributes_table do
      row :title
      row :genre
      row :release_year
      row :rating
      row :director
      row :duration
      row :description
      row :plan
      row :poster do
        image_tag movie.poster.url if movie.poster.attached?
      end
    end
    active_admin_comments
  end

  # Form page for creating or updating a movie
  form do |f|
    f.inputs 'Movie Details' do
      f.input :title
      f.input :genre
      f.input :release_year
      f.input :rating
      f.input :director
      f.input :duration
      f.input :description
      f.input :plan, as: :select, collection: Movie.plans.keys.map { |plan| [plan.capitalize, plan] }
      f.input :poster, as: :file
    end
    f.actions
  end
end
