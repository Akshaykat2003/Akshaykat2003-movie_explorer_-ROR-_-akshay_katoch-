# app/models/wishlist.rb
class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  validates :user_id, uniqueness: { scope: :movie_id, message: "already wishlisted this movie" }

  def self.add_to_wishlist(user, movie_id)
    movie = Movie.find_by(id: movie_id)
    return { success: false, errors: ["Movie not found"] } unless movie

    wishlist = user.wishlists.find_by(movie_id: movie_id)
    if wishlist
      # Movie is already wishlisted, so remove it (toggle off)
      wishlist.destroy
      { success: true, data: { message: "Movie removed from wishlist", movie_id: movie.id, is_wishlisted: false } }
    else
      # Movie is not wishlisted, so add it (toggle on)
      new_wishlist = user.wishlists.build(movie: movie)
      if new_wishlist.save
        { success: true, data: { message: "Movie added to wishlist", movie_id: movie.id, is_wishlisted: true } }
      else
        { success: false, errors: new_wishlist.errors.full_messages }
      end
    end
  end

  def self.remove_from_wishlist(user, movie_id)
    wishlist = user.wishlists.find_by(movie_id: movie_id)
    if wishlist
      wishlist.destroy
      { success: true, data: { message: "Movie removed from wishlist", movie_id: movie_id.to_i, is_wishlisted: false } }
    else
      { success: false, errors: ["Movie not in wishlist"] }
    end
  end

  def self.clear_wishlist(user)
    count = user.wishlists.destroy_all.length
    { success: true, data: { message: "All wishlisted movies removed", count: count } }
  end

  def self.wishlisted_movies(user)
    movies = user.wishlisted_movies.map do |movie|
      movie.as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]).merge(is_wishlisted: true)
    end
    { success: true, data: movies }
  end
end