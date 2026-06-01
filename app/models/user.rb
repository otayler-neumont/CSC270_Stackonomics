class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :specimens, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_specimens, through: :likes, source: :specimen

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "is not a valid email address" }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # First name (or the whole name) for compact UI labels and avatars.
  def display_name
    name.presence || email_address.split("@").first
  end

  def initials
    display_name.split(/\s+/).map { |part| part[0] }.first(2).join.upcase
  end
end
