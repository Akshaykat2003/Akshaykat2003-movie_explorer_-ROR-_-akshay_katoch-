ActiveAdmin.register Movie do
  permit_params :title, :genre, :release_year, :rating, :director, :duration, :description, :plan, :poster, :banner

  controller do
    private

    def authorize_admin_only
      unless current_user && current_user.role == 'admin'
        redirect_to admin_dashboard_path, alert: 'You do not have permission to perform this action.'
      end
    end
  end

  filter :title
  filter :genre
  filter :release_year
  filter :rating
  filter :plan, as: :select, collection: Movie.plans.keys.map { |plan| [plan.capitalize, plan] }

  index do
  selectable_column
  id_column
  column :title
  column :genre
  column :release_year
  column :rating
  column :director
  column :duration
  column :plan
  column :poster do |movie|
    if movie.poster.attached?
      image_tag movie.poster.url, style: 'border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.2); width: 60px; height: 60px; object-fit: cover;'
    end
  end
  column :banner do |movie|
    if movie.banner.attached?
      image_tag movie.banner.url, style: 'border-radius: 5px; width: 60px; height: 60px; object-fit: cover;'
    end
  end
  column "📡 API Access" do
    link_to "🎥 Fetch All Movies", "/api/v1/movies/all", target: "_blank", style: "color: #1e88e5;"
  end
  actions
end


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
      row :banner do
        image_tag movie.banner.url if movie.banner.attached?
      end
    end
    active_admin_comments
  end

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
      f.input :banner, as: :file
    end
    f.actions
  end
end