module Api
  module V1
    class MoviesController < ApplicationController
      before_action :set_movie, only: [:show, :update, :destroy]
      before_action :authorize_supervisor_or_admin, only: [:create, :update, :destroy]
      skip_before_action :authenticate_request, only: [:index, :show]

      def index
        movies = Movie.search_and_filter(params)
        paginated_movies = movies.page(params[:page]).per(12)
        render json: {
          movies: paginated_movies.as_json(
            only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
            methods: [:poster_url, :banner_url]
          ),
          total_pages: paginated_movies.total_pages,
          current_page: paginated_movies.current_page
        }, status: :ok
      rescue => e
        Rails.logger.error "Error in MoviesController#index: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def show
        render json: @movie.as_json(
          only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
          methods: [:poster_url, :banner_url]
        ), status: :ok
      rescue => e
        Rails.logger.error "Error in MoviesController#show: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def create
        result = Movie.create_movie(movie_params)
        if result[:success]
          begin
            send_new_movie_notification(result[:movie])
          rescue => e
            Rails.logger.error "Failed to send new movie notification for movie #{result[:movie].id}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end

          render json: result[:movie].as_json(
            only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
            methods: [:poster_url, :banner_url]
          ), status: :created
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Error in MoviesController#create: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def update
        result = @movie.update_movie(movie_params)
        if result[:success]
          render json: result[:movie].as_json(
            only: [:id, :title, :genre, :release_year, :rating, :director, :duration, :description, :plan],
            methods: [:poster_url, :banner_url]
          ), status: :ok
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      rescue => e
        Rails.logger.error "Error in MoviesController#update: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      def destroy
        @movie.destroy
        render json: { message: "Movie deleted successfully" }, status: :ok
      rescue => e
        Rails.logger.error "Error in MoviesController#destroy: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { error: "Internal server error" }, status: :internal_server_error
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

      def authorize_supervisor_or_admin
        unless @current_user&.role&.in?(%w[supervisor admin])
          render json: { error: "Forbidden: You do not have permission to perform this action" }, status: :forbidden
        end
      end

      def send_new_movie_notification(movie)
        tokens = User.where(notifications_enabled: true).where.not(device_token: nil).pluck(:device_token)
        Rails.logger.info("Found #{tokens.count} eligible users for notification: #{tokens}")

        if tokens.empty?
          Rails.logger.info("No users eligible for notification for movie #{movie.id} (no device tokens or notifications disabled)")
          return
        end

        Rails.logger.info("Sending notification to tokens: #{tokens}, title: New Movie Added!, body: '#{movie.title} has been added to Movie Explorer+.', data: #{ { movie_id: movie.id.to_s, url: "/movies/#{movie.id}" }.inspect }")

        fcm_service = FcmService.new
        result = fcm_service.send_notification(
          tokens,
          "New Movie Added!",
          "#{movie.title} has been added to Movie Explorer+.",
          movie_id: movie.id.to_s,
          url: "/movies/#{movie.id}"
        )

        if result[:status_code] == 200
          Rails.logger.info("Notification sent successfully for movie #{movie.id}")
        else
          Rails.logger.warn("Notification failed for movie #{movie.id}: #{result[:body]}")
        end
      rescue StandardError => e
        Rails.logger.error("Failed to send new movie notification for movie #{movie.id}: #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
  end
end