module Api
  module V1
    class MoviesController < ApplicationController
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_supervisor_or_admin, only: [:create, :update, :destroy]

    
      skip_before_action :authenticate_request, only: [:index, :show]
      skip_before_action :authorize_supervisor_or_admin, only: [:index, :show]

      def index
        movies = Movie.search_and_filter(params)
        paginated_movies = movies.page(params[:page]).per(10)
        render json: {
          movies: paginated_movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :plan], methods: [:poster_url, :banner_url]),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page 
        }, status: :ok
      rescue StandardError => e

        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def show
        render json: @movie.as_json(
          only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
          methods: [:poster_url, :banner_url]
        ), status: :ok
      rescue StandardError => e
       
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def create
        
        result = Movie.create_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url]), status: :created
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      rescue StandardError => e
       
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def update
       
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url]), status: :ok
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      rescue StandardError => e
 
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def destroy
  
        @movie.destroy
   
        render json: { message: "Movie deleted successfully" }, status: :ok
      rescue StandardError => e
      
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def set_movie
        @movie = Movie.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
        return 
      end

      def movie_params
        params.permit(:title, :genre, :release_year, :rating, :director, :duration, :description, :plan, :poster, :banner)
      end

      def authorize_supervisor_or_admin
        unless @current_user&.role&.in?(['supervisor', 'admin'])

          render json: { error: 'Forbidden: You do not have permission to perform this action' }, status: :forbidden
          return 
        end
      end
    end
  end
end