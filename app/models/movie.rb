class Movie < ApplicationRecord
  has_one_attached :poster
  has_one_attached :banner

  enum plan: { basic: 0, gold: 1, platinum: 2 }

  validates :title, presence: true
  validates :genre, presence: true
  validates :release_year, presence: true
  validates :rating, presence: true
  validates :plan, presence: true

  # Add 'plan' to the ransackable attributes
  def self.ransackable_attributes(auth_object = nil)
    super + ["plan"]  # Add 'plan' to the list of searchable attributes
  end

  def self.ransackable_associations(auth_object = nil)
    ["banner_attachment", "banner_blob", "poster_attachment", "poster_blob"]
  end

  # Class method for searching and filtering movies
  def self.search_and_filter(params)
    movies = Movie.all

    movies = movies.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    movies = movies.where(genre: params[:genre]) if params[:genre].present?

    movies
  end

  # Class method for creating a movie
  def self.create_movie(params)
    movie = Movie.new(params)
    if movie.save
      { success: true, movie: movie }
    else
      { success: false, errors: movie.errors.full_messages }
    end
  end

  # Instance method for updating a movie
  def update_movie(params)
    if update(params)
      { success: true, movie: self }
    else
      { success: false, errors: errors.full_messages }
    end
  end

  # Instance methods to get the URLs for poster and banner images
  def poster_url
    Rails.application.routes.url_helpers.rails_blob_path(poster, only_path: true) if poster.attached?
  end

  def banner_url
    Rails.application.routes.url_helpers.rails_blob_path(banner, only_path: true) if banner.attached?
  end
end
