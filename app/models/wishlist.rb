class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :movie
  validates :user_id, uniqueness: { scope: :movie_id, message: "already wishlisted this movie" }

  def self.add_to_wishlist(user, movie_id)
    movie = Movie.find_by(id: movie_id)
    return { success: false, errors: ["Movie not found"] } unless movie

    wishlist = user.wishlists.build(movie: movie)
    if wishlist.save
      { success: true, data: { message: "Movie added to wishlist", movie_id: movie.id } }
    else
      { success: false, errors: wishlist.errors.full_messages }
    end
  end


  def self.remove_from_wishlist(user, movie_id)
    wishlist = user.wishlists.find_by(movie_id: movie_id)
    if wishlist
      wishlist.destroy
      { success: true, data: { message: "Movie removed from wishlist", movie_id: movie_id.to_i } }
    else
      { success: false, errors: ["Movie not in wishlist"] }
    end
  end

  
  def self.wishlisted_movies(user)
    { success: true, data: user.wishlisted_movies }
  end
end