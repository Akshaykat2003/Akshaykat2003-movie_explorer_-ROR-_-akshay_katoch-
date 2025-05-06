class Movie < ApplicationRecord
  has_one_attached :poster
  has_one_attached :banner

  enum plan: { basic: 0, gold: 1, platinum: 2 }

  validates :title, presence: true
  validates :genre, presence: true
  validates :release_year, presence: true
  validates :rating, presence: true
  validates :plan, presence: true

  def self.ransackable_attributes(auth_object = nil)
    super + ["plan"]  
  end

  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "poster_attachment", "poster_blob"]
  end

  def self.search_and_filter(params)
    movies = Movie.all

    movies = movies.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    movies = movies.where(genre: params[:genre]) if params[:genre].present?

    movies
  end

  def self.create_movie(params)
    movie = Movie.new(params.except(:poster, :banner))
    if movie.save
      movie.poster.attach(params[:poster]) if params[:poster].present?
      movie.banner.attach(params[:banner]) if params[:banner].present?
      { success: true, movie: movie }
    else
      { success: false, errors: movie.errors.full_messages }
    end
  end

  def update_movie(params)
    if update(params)
      { success: true, movie: self }
    else
      { success: false, errors: errors.full_messages }
    end
  end

  def poster_url
    if poster.attached?
      begin
        Cloudinary::Utils.cloudinary_url(poster.key, resource_type: :image)
      rescue StandardError => e
        Rails.logger.error "Failed to generate poster_url for movie #{id}: #{e.message}"
        nil
      end
    end
  end

  def banner_url
    if banner.attached?
      begin
        Cloudinary::Utils.cloudinary_url(banner.key, resource_type: :image)
      rescue StandardError => e
        Rails.logger.error "Failed to generate banner_url for movie #{id}: #{e.message}"
        nil
      end
    end
  end
end