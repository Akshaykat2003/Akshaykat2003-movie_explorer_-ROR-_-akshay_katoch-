require 'httparty'
require 'googleauth'
require 'json'

class FcmService
  def initialize
    @credentials = Rails.application.credentials.dig(:fcm, :service_account)
    Rails.logger.info("FCM Service Account Credentials: #{@credentials ? 'Loaded' : 'Missing'}")
    raise 'FCM service account credentials are not set in Rails credentials' unless @credentials
    raise 'FCM service account private key is missing or invalid' unless @credentials[:private_key]&.include?('BEGIN PRIVATE KEY')

    # Log the first 100 characters of the credentials for debugging
    credentials_json = @credentials.to_json
    Rails.logger.info("Service Account JSON Content (first 100 chars): #{credentials_json[0..100]}...")

    # Initialize Google Auth credentials for OAuth2 token generation
    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials_json),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
    raise 'Failed to initialize Google Auth credentials' if @authorizer.nil?
  end

  def send_notification(device_tokens, title, body, data = {})
    # Deduplicate device tokens to avoid sending the same notification multiple times to the same device
    tokens = Array(device_tokens).map(&:to_s).uniq.reject do |token|
      if token.strip.empty?
        Rails.logger.warn("Rejected empty FCM token")
        true
      elsif token.include?('test')
        Rails.logger.warn("Rejected FCM token containing 'test': #{token}")
        true
      else
        false
      end
    end

    return { status_code: 200, body: 'No valid device tokens' } if tokens.empty?

    # Fetch OAuth2 access token
    begin
      access_token = @authorizer.fetch_access_token!['access_token']
      Rails.logger.info("Fetched FCM access token: #{access_token[0..20]}...")
    rescue StandardError => e
      Rails.logger.error("Failed to fetch OAuth2 access token: #{e.message}\n#{e.backtrace.join("\n")}")
      raise "Failed to fetch OAuth2 access token: #{e.message}"
    end
    raise 'Fetched OAuth2 access token is empty' if access_token.nil? || access_token.empty?

    # FCM HTTP v1 API endpoint
    url = "https://fcm.googleapis.com/v1/projects/#{@credentials[:project_id]}/messages:send"
    Rails.logger.info("FCM API Endpoint: #{url}")

    # HTTP v1 API payload structure
    payload = {
      message: {
        notification: {
          title: title.to_s,
          body: body.to_s
        },
        data: data.transform_values(&:to_s)
      }
    }

    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }

    begin
      responses = tokens.map do |token|
        payload[:message][:token] = token
        Rails.logger.info("Sending FCM to token: #{token[0..20]}... with payload: #{payload.inspect}")

        response = HTTParty.post(
          url,
          body: payload.to_json,
          headers: headers
        )

        parsed_body = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
        Rails.logger.info("FCM Response for token #{token[0..20]}...: Status: #{response.code}, Body: #{parsed_body.inspect}")
        Rails.logger.debug("Full FCM Response Headers: #{response.headers.inspect}") if response.code != 200

        {
          token: token,
          status_code: response.code,
          body: parsed_body
        }
      end

      status_code = responses.all? { |r| r[:status_code]&.to_i == 200 } ? 200 : 500
      body = responses.map { |r| "Token #{r[:token][0..20]}...: #{r[:body]}" }.join("; ")

      {
        status_code: status_code,
        body: body,
        response: responses
      }
    rescue StandardError => e
      Rails.logger.error("FCM Error: #{e.message}\n#{e.backtrace.join("\n")}")
      { status_code: 500, body: "FCM Error: #{e.message}" }
    end
  end
end