require 'httparty'
require 'googleauth'

class FirebaseService
  FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/fir-pushnotification-39474/messages:send"
  SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

  def self.access_token
    # Fetch service account credentials from Rails credentials
    service_account = Rails.application.credentials.dig(:fcm, :service_account)

    # Configure the authorizer using the service account
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(service_account.to_json),
      scope: SCOPE
    )

    # Fetch the access token
    authorizer.fetch_access_token!["access_token"]
  end

  def self.send_notification(tokens:, title:, body:, data: {})
    return if tokens.empty?

    Rails.logger.info("Sending notification to tokens: #{tokens}, title: #{title}, body: #{body}, data: #{data}")

    failed = false
    access_token = self.access_token

    tokens.each do |token|
      message = {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: data.transform_keys(&:to_s).transform_values(&:to_s)
      }

      begin
        response = HTTParty.post(
          FCM_ENDPOINT,
          headers: {
            "Authorization" => "Bearer #{access_token}",
            "Content-Type" => "application/json"
          },
          body: { message: message }.to_json
        )

        if response.success?
          Rails.logger.info("FCM Response: #{response.body}")
        else
          Rails.logger.error("FCM Error: #{response.body}")
          failed = true
        end
      rescue => e
        Rails.logger.error("FCM Error: #{e.message}")
        failed = true
      end
    end

    raise "Failed to send notification to some devices" if failed
  end
end