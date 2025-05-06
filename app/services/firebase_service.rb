require 'googleauth'
require 'httparty'
require 'json'

class FirebaseService
  include HTTParty
  base_uri 'https://fcm.googleapis.com'

  class << self
    def send_notification(tokens:, title:, body:, data: {})
      access_token = fetch_access_token
      unless access_token.is_a?(String)
        Rails.logger.error("Failed to fetch Firebase access token: #{access_token}")
        return { success: false, errors: ["Failed to fetch Firebase access token: #{access_token}"] }
      end

      headers = {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }

      message = {
        message: {
          notification: {
            title: title,
            body: body
          },
          data: data.transform_keys(&:to_s).transform_values(&:to_s),
          token: nil
        }
      }

      errors = []
      tokens.each do |token|
        message[:message][:token] = token
        begin
          response = post(
            "/v1/projects/#{Rails.application.credentials.dig(:fcm, :service_account, :project_id)}/messages:send",
            headers: headers,
            body: message.to_json
          )

          unless response.success?
            error_body = response.parsed_response || response.body
            Rails.logger.error("FCM request failed for token #{token}: #{response.code} - #{error_body}")
            errors << "Token #{token}: #{error_body}"
          end
        rescue HTTParty::Error => e
          Rails.logger.error("FCM network error for token #{token}: #{e.message}")
          errors << "Token #{token}: Network error - #{e.message}"
        end
      end

      if errors.empty?
        { success: true, errors: [] }
      else
        { success: false, errors: errors }
      end
    rescue StandardError => e
      Rails.logger.error("FCM service error: #{e.message}\n#{e.backtrace.join("\n")}")
      { success: false, errors: ["FCM Error: #{e.message}"] }
    end

    private

    def fetch_access_token
      credentials = Rails.application.credentials.dig(:fcm, :service_account)
      unless credentials && credentials[:private_key] && credentials[:private_key].include?('BEGIN PRIVATE KEY')
        Rails.logger.error("Invalid Firebase service account credentials: #{credentials.inspect}")
        return "Firebase service account credentials are missing or invalid"
      end

      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials.to_json),
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )

      token_data = authorizer.fetch_access_token!
      unless token_data && token_data['access_token']
        Rails.logger.error("Failed to fetch access token: No access_token in response - #{token_data.inspect}")
        return "Failed to fetch access token: No access_token in response"
      end

      token_data['access_token']
    rescue Google::Auth::Error => e
      Rails.logger.error("Google Auth error: #{e.message}\n#{e.backtrace.join("\n")}")
      "Failed to fetch Firebase access token: #{e.message}"
    rescue StandardError => e
      Rails.logger.error("Unexpected error fetching access token: #{e.message}\n#{e.backtrace.join("\n")}")
      "Failed to fetch Firebase access token: #{e.message}"
    end
  end
end