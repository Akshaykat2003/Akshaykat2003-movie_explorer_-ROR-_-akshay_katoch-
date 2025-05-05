require 'stripe'

if Rails.application.credentials.dig(:stripe, :secret_key).present?
  Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
else
  Rails.logger.warn("Stripe secret key is missing in credentials!")
end
