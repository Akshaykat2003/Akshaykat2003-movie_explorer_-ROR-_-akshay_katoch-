
module Api
  module V1
    class WishlistsController < ApplicationController
      before_action :authenticate_request
      skip_before_action :verify_authenticity_token, only: [:create, :destroy, :clear]

      def create
        result = Wishlist.add_to_wishlist(current_user, params[:movie_id])
        if result[:success]
          render json: result[:data], status: :ok
        else
          render json: { errors: result[:errors] }, status: result[:errors].include?("Movie not found") ? :not_found : :unprocessable_entity
        end
      end

      def destroy
        result = Wishlist.remove_from_wishlist(current_user, params[:movie_id])
        if result[:success]
          render json: result[:data], status: :ok
        else
          render json: { errors: result[:errors] }, status: :not_found
        end
      end

      def clear
        result = Wishlist.clear_wishlist(current_user)
        render json: result[:data], status: :ok
      end

      def index
        result = Wishlist.wishlisted_movies(current_user)
        render json: result[:data], status: :ok
      end
    end
  end
end