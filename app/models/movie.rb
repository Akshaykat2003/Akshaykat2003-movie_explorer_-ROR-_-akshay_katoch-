class Movie < ApplicationRecord
  has_one_attached :poster
  has_one_attached :banner

  enum plan: { basic: 0, gold: 1, platinum: 2 }

  validates :title, :genre, :release_year, :rating, :plan, presence: true

  def self.ransackable_attributes(auth_object = nil)
    super + ["plan"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "poster_attachment", "poster_blob"]
  end

  def self.search_and_filter(params)
    movies = all
    movies = movies.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    movies = movies.where(genre: params[:genre]) if params[:genre].present?
    movies
  end

  def self.create_movie(params)
    movie = new(params.except(:poster, :banner))
    if movie.save
      movie.poster.attach(params[:poster]) if params[:poster].present?
      movie.banner.attach(params[:banner]) if params[:banner].present?
      { success: true, movie: movie }
    else
      { success: false, errors: movie.errors.full_messages }
    end
  end

  def update_movie(params)
    update(params) ? { success: true, movie: self } : { success: false, errors: errors.full_messages }
  end

  def poster_url
    Cloudinary::Utils.cloudinary_url(poster.key, resource_type: :image) if poster.attached?
  rescue StandardError
    nil
  end

  def banner_url
    Cloudinary::Utils.cloudinary_url(banner.key, resource_type: :image) if banner.attached?
  rescue StandardError
    nil
  end

  def send_new_movie_notification
    tokens = User.where(notifications_enabled: true).where.not(device_token: nil).pluck(:device_token)
    return if tokens.empty?

    FcmService.new.send_notification(
      tokens,
      "New Movie Added!",
      "#{title} has been added to Movie Explorer+.",
      movie_id: id.to_s,
      url: "/movies/#{id}"
    )
  end
end