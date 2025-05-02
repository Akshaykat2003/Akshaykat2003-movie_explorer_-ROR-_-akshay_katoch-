class User < ApplicationRecord
  has_secure_password

  
  has_one :subscription, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
   
    ["first_name", "last_name", "email", "mobile_number", "role"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: VALID_EMAIL_REGEX }
  validates :password, presence: true, length: { minimum: 6 }
  validates :mobile_number, presence: true, length: { is: 10 }, numericality: { only_integer: true }
  validates :role, presence: true, inclusion: { in: %w[user supervisor] }

  def self.register(params)
    params[:role] ||= 'user'
    user = User.new(params)
    if user.save
      { success: true, user: user }
    else
      { success: false, errors: user.errors.full_messages }
    end
  end

  def self.authenticate(email, password)
    user = User.find_by(email: email)
    return nil unless user&.authenticate(password)
    user
  end

  def generate_jwt
    payload = { user_id: id, exp: 7.days.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_jwt(token)
    decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    User.find(decoded["user_id"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end
end
