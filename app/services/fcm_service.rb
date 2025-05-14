require 'httparty'
require 'googleauth'
require 'json'

class FcmService
  def initialize
    @fcm_credentials = Rails.application.credentials.dig(:fcm, :service_account)
    if @fcm_credentials.nil?
      raise 'FCM service account credentials are not set in Rails credentials'
    end
    unless @fcm_credentials[:private_key]&.include?('BEGIN PRIVATE KEY')
      raise 'FCM service account private key is missing or invalid'
    end
    @google_auth = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(@fcm_credentials.to_json),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
    if @google_auth.nil?
      raise 'Failed to initialize Google Auth credentials'
    end
  end

  def send_notification(device_tokens, title, body, data = {})
    valid_tokens = clean_device_tokens(device_tokens)
    if valid_tokens.empty?
      return { status_code: 200, body: 'No valid device tokens' }
    end
    access_token = fetch_access_token
    notification_results = send_notifications_to_tokens(valid_tokens, title, body, data, access_token)
    summarize_results(notification_results)
  rescue StandardError => error
    { status_code: 500, body: "FCM Error: #{error.message}" }
  end

  private

  def clean_device_tokens(tokens)
    Array(tokens).map(&:to_s).uniq.reject do |token|
      token.strip.empty? || token.include?('test')
    end
  end

  def fetch_access_token
    token_info = @google_auth.fetch_access_token!
    access_token = token_info['access_token']
    if access_token.nil? || access_token.empty?
      raise 'Fetched OAuth2 access token is empty'
    end
    access_token
  end

  def build_payload(title, body, data, token)
    {
      message: {
        notification: {
          title: title.to_s,
          body: body.to_s
        },
        data: data.transform_values(&:to_s),
        token: token
      }
    }
  end

  def send_notifications_to_tokens(tokens, title, body, data, access_token)
    url = "https://fcm.googleapis.com/v1/projects/#{@fcm_credentials[:project_id]}/messages:send"
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    tokens.map do |token|
      payload = build_payload(title, body, data, token)
      response = HTTParty.post(url, body: payload.to_json, headers: headers)
      response_body = JSON.parse(response.body) rescue response.body
      {
        token: token,
        status_code: response.code,
        body: response_body
      }
    end
  end

  def summarize_results(results)
    overall_status = results.all? { |result| result[:status_code] == 200 } ? 200 : 500
    summary_message = results.map do |result|
      short_token = result[:token][0..20] + "..."
      "Token #{short_token}: #{result[:body]}"
    end.join("; ")
    {
      status_code: overall_status,
      body: summary_message,
      response: results
    }
  end
end