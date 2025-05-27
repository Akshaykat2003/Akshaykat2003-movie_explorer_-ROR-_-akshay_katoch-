module Api
  module V1
    class MoviesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_supervisor_or_admin, only: [:create, :update, :destroy]
      skip_before_action :authenticate_request, only: [:index, :all] 

      def index
        movies = Movie.search_and_filter(params).page(params[:page]).per(12)
        render json: {
          movies: movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]),
          total_pages: movies.total_pages,
          current_page: movies.current_page
        }, status: :ok
      rescue StandardError
        render json: { errors: ["Internal server error"] }, status: :internal_server_error
      end

      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          result[:movie].send_new_movie_notification
          render json: result[:movie].as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      rescue StandardError => e
        render json: { errors: ["Internal server error: #{e.message}"] }, status: :internal_server_error
      end

      def all
        movies = Movie.all
        render json: { movies: movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]) }, status: :ok
      rescue StandardError
        render json: { errors: ["Internal server error"] }, status: :internal_server_error
      end

      def show
        unless can_access_movie?(@movie)
          render json: { errors: ["Access denied: Your subscription plan does not allow access to this movie"] }, status: :forbidden
          return
        end
        render json: @movie.as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]), status: :ok
      rescue StandardError => e
        render json: { errors: ["Internal server error: #{e.message}"] }, status: :internal_server_error
      end

      def update
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan], methods: [:poster_url, :banner_url]), status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      rescue StandardError
        render json: { errors: ["Internal server error"] }, status: :internal_server_error
      end

      def destroy
        @movie.destroy
        render json: { message: "Movie deleted successfully" }, status: :ok
      rescue StandardError
        render json: { errors: ["Internal server error"] }, status: :internal_server_error
      end

      private

      def set_movie
        @movie = Movie.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: ["Movie not found"] }, status: :not_found
      end

      def movie_params
        params.permit(:title, :genre, :release_year, :rating, :director, :duration, :description, :plan, :poster, :banner)
      end

      def can_access_movie?(movie)
  begin
    @current_user.ensure_subscription
  rescue StandardError => e
    Rails.logger.info "Access denied: Subscription creation failed for user #{@current_user.id}: #{e.message}"
    return false
  end

  subscription = @current_user.subscription
  unless subscription&.active?
    Rails.logger.info "Access denied: Subscription not active for user #{@current_user.id}. Status: #{subscription&.status}"
    return false
  end

  user_plan_value = Movie.plans[subscription.plan]
  movie_plan_value = Movie.plans[movie.plan]
  unless user_plan_value >= movie_plan_value
    Rails.logger.info "Access denied: User plan '#{subscription.plan}' (#{user_plan_value}) cannot access movie plan '#{movie.plan}' (#{movie_plan_value}) for user #{@current_user.id}"
    return false
  end

  true
end
    end
  end
end