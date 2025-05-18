# app/models/blacklisted_token.rb
class BlacklistedToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.blacklisted?(token)
    return false unless token.is_a?(String)
    where(token: token).exists?
  end

  def self.cleanup_expired
    where('expires_at < ?', Time.current).destroy_all
  end

  def self.blacklist(token, secret_key_base)
    return { success: false, error: 'Token is missing' } if token.blank?

    begin
      decoded = JWT.decode(token, secret_key_base, true, algorithm: 'HS256').first
      expires_at = Time.zone.at(decoded['exp'])
      return { success: false, error: 'Token already expired' } if expires_at < Time.current

      create!(token: token, expires_at: expires_at)
      { success: true, message: 'Logout successful' }
    rescue JWT::ExpiredSignature
      { success: false, error: 'Token already expired' }
    rescue JWT::DecodeError
      { success: false, error: 'Invalid token' }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    end
  end
end