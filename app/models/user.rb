class User < ApplicationRecord
  has_secure_password
  has_one :subscription, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_many :wishlisted_movies, through: :wishlists, source: :movie
  has_one_attached :profile_picture

  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\z/
  VALID_IMAGE_TYPES = %w[image/png image/jpg image/jpeg].freeze
  MAX_IMAGE_SIZE = 5.megabytes

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

  def self.update_preferences(user, params)
    update_params = params.to_h.dup
    update_params[:notifications_enabled] = update_params[:notifications_enabled] != false if update_params.key?(:notifications_enabled)
    update_params.delete(:device_token) if update_params[:device_token] && user.device_token == update_params[:device_token]
    if update_params.empty?
      return { success: true, message: "Preferences unchanged" }
    end
    if user.update(update_params)
      { success: true, message: "Preferences updated successfully", user: user }
    else
      { success: false, errors: user.errors.full_messages }
    end
  rescue ActiveRecord::RecordNotUnique => e
    { success: false, errors: ["Device token is already in use by another user"] }
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

  def profile_picture_url
    Cloudinary::Utils.cloudinary_url(profile_picture.key, resource_type: :image) if profile_picture.attached?
  rescue StandardError
    nil
  end

  def self.update_profile_picture(user, profile_picture)
    return { success: false, errors: ["Profile picture file is required"], status: :bad_request } unless profile_picture.present?
    return { success: false, errors: ["User must be saved before attaching a profile picture"], status: :unprocessable_entity } unless user.persisted?

    unless VALID_IMAGE_TYPES.include?(profile_picture.content_type)
      return { success: false, errors: ["Profile picture must be a valid image format (PNG, JPG, JPEG)"], status: :unprocessable_entity }
    end

    if profile_picture.size > MAX_IMAGE_SIZE
      return { success: false, errors: ["Profile picture must be less than 5MB"], status: :unprocessable_entity }
    end

    ActiveRecord::Base.transaction do
      user.profile_picture.purge if user.profile_picture.attached?
      user.profile_picture.attach(profile_picture)
      user.save!
    end

    { success: true, message: "Profile picture updated successfully", profile_picture_url: user.profile_picture_url, status: :ok }
  rescue ActiveStorage::Error, ActiveRecord::RecordInvalid => e
    Rails.logger.error("Profile picture update error: #{e.message}")
    { success: false, errors: ["Failed to update profile picture: #{e.message}"], status: :unprocessable_entity }
  rescue StandardError => e
    Rails.logger.error("Profile picture update error: #{e.message}")
    { success: false, errors: ["Internal server error: #{e.message}"], status: :internal_server_error }
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