class User < ApplicationRecord
  has_secure_password
  has_one :subscription, dependent: :destroy

  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: VALID_EMAIL_REGEX }
  validates :mobile_number, presence: true, length: { is: 10 }, numericality: { only_integer: true }
  validates :role, presence: true, inclusion: { in: %w[user supervisor] }

  before_validation :downcase_email

  def self.ransackable_attributes(auth_object = nil)
    ["first_name", "last_name", "email", "mobile_number", "role"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.register(params)
    params[:role] = 'user'
    user = User.new(params)
    user.save ? { success: true, user: user } : { success: false, errors: user.errors.full_messages }
  end

  def self.authenticate(email, password)
    user = find_by(email: email.downcase)
    user if user&.authenticate(password)
  end

  def generate_jwt
    JWT.encode({ user_id: id, exp: 1.day.from_now.to_i, role: role }, Rails.application.credentials.secret_key_base)
  end

  def self.decode_jwt(token)
    decoded = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    find(decoded["user_id"])
  rescue JWT::ExpiredSignature, JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  def as_json_with_plan
    as_json(except: [:password_digest]).merge('role' => role, 'active_plan' => active_plan)
  end

  def active_plan
    ensure_subscription
    subscription&.active? ? subscription.plan : 'basic'
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def ensure_subscription
    return if subscription.present?
    Subscription.create_default_for_user(self)
    reload 
  end
end