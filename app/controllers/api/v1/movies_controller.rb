module Api
  module V1
    class MoviesController < ApplicationController
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_supervisor_or_admin, only: [:create, :update, :destroy]

  
      def index
        movies = Movie.search_and_filter(params)
        paginated_movies = movies.page(params[:page]).per(10)

        render json: {
          movies: paginated_movies.as_json(only: [:id, :title, :genre, :release_year, :rating, :plan], methods: [:poster_url, :banner_url]),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }
      end

      def show
        render json: @movie.as_json(
          only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
          methods: [:poster_url, :banner_url]
        )
      end

      # POST /movies
      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url]), status: :created
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /movies/:id
      def update
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(methods: [:poster_url, :banner_url])
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /movies/:id
      def destroy
        @movie.destroy
        head :no_content
      end

      private

      def set_movie
        @movie = Movie.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Movie not found" }, status: :not_found
      end

      def movie_params
        params.permit(:title, :genre, :release_year, :rating, :director, :duration, :description, :plan, :poster, :banner)
      end

      # Check if the current user is a supervisor or admin
      def authorize_supervisor_or_admin
        unless @current_user&.role == 'supervisor' || @current_user&.role == 'admin'
          render json: { error: 'Forbidden: You do not have permission to perform this action' }, status: :forbidden
        end
      end
    end
  end
end
