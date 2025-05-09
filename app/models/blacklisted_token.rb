class BlacklistedToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.blacklisted?(token)
    exists?(token: token)
  end

  def self.cleanup_expired
    where('expires_at <= ?', Time.now).delete_all
  end

  def self.blacklist(token, secret_key)
    return { success: false, error: 'Token is missing' } unless token

    decoded_token = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })[0]
    expires_at = Time.at(decoded_token['exp'])
    return { success: false, error: 'Token already expired' } if expires_at <= Time.now

    create!(token: token, expires_at: expires_at)
    { success: true, message: 'Logout successful' }
  rescue JWT::DecodeError
    { success: false, error: 'Invalid token' }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end
end