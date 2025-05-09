require 'httparty'
require 'googleauth'
require 'json'

class FcmService
  def initialize
    @credentials = Rails.application.credentials.dig(:fcm, :service_account)
    raise 'FCM service account credentials are not set in Rails credentials' unless @credentials
    raise 'FCM service account private key is missing or invalid' unless @credentials[:private_key]&.include?('BEGIN PRIVATE KEY')

    @authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(@credentials.to_json),
      scope: 'https://www.googleapis.com/auth/firebase.messaging'
    )
    raise 'Failed to initialize Google Auth credentials' if @authorizer.nil?
  end

  def send_notification(device_tokens, title, body, data = {})
    tokens = Array(device_tokens).map(&:to_s).uniq.reject { |token| token.strip.empty? || token.include?('test') }
    return { status_code: 200, body: 'No valid device tokens' } if tokens.empty?

    access_token = @authorizer.fetch_access_token!['access_token']
    raise 'Fetched OAuth2 access token is empty' if access_token.nil? || access_token.empty?

    url = "https://fcm.googleapis.com/v1/projects/#{@credentials[:project_id]}/messages:send"
    payload = { message: { notification: { title: title.to_s, body: body.to_s }, data: data.transform_values(&:to_s) } }
    headers = { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }

    responses = tokens.map do |token|
      payload[:message][:token] = token
      response = HTTParty.post(url, body: payload.to_json, headers: headers)
      parsed_body = JSON.parse(response.body) rescue response.body
      { token: token, status_code: response.code, body: parsed_body }
    end

    status_code = responses.all? { |r| r[:status_code]&.to_i == 200 } ? 200 : 500
    body = responses.map { |r| "Token #{r[:token][0..20]}...: #{r[:body]}" }.join("; ")
    { status_code: status_code, body: body, response: responses }
  rescue StandardError => e
    { status_code: 500, body: "FCM Error: #{e.message}" }
  end
end