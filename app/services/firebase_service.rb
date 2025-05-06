require 'googleauth'

class FirebaseService
  class << self
    def send_notification(tokens:, title:, body:, data: {})
      access_token = fetch_access_token
      return { success: false, errors: ["Failed to fetch Firebase access token: #{access_token}"] } unless access_token.is_a?(String)

      uri = URI.parse("https://fcm.googleapis.com/v1/projects/#{Rails.application.credentials.dig(:fcm, :service_account, :project_id)}/messages:send")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Authorization'] = "Bearer #{access_token}"
      request['Content-Type'] = 'application/json'

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
        request.body = message.to_json

        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          errors << "Token #{token}: #{response.body}"
        end
      end

      if errors.empty?
        { success: true, errors: [] }
      else
        { success: false, errors: errors }
      end
    rescue StandardError => e
      { success: false, errors: ["FCM Error: #{e.message}"] }
    end

    private

    def fetch_access_token
      credentials = Rails.application.credentials.dig(:fcm, :service_account)
      unless credentials && credentials[:private_key] && credentials[:private_key].include?('BEGIN PRIVATE KEY')
        return "Firebase service account credentials are missing or invalid"
      end

      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials.to_json),
        scope: 'https://www.googleapis.com/auth/firebase.messaging'
      )
      authorizer.fetch_access_token!['access_token']
    rescue StandardError => e
      "Failed to fetch Firebase access token: #{e.message}"
    end
  end
end