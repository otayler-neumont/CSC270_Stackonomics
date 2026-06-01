class Specimen < ApplicationRecord
  TINTS = %w[slate rose blue emerald fuchsia purple sky cyan indigo red pink teal].freeze

  # optional: legacy specimens (and the persistent prod volume) may have no
  # owner until seeds backfill them. New specimens always set an owner.
  belongs_to :user, optional: true
  has_many :comments, -> { order(created_at: :asc) }, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user

  validates :name, presence: true
  validates :mohs, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :tint, inclusion: { in: TINTS }, allow_nil: true

  scope :for_user, ->(user) { where(user: user) }

  def owned_by?(candidate)
    candidate.present? && user_id == candidate.id
  end

  def liked_by?(candidate)
    return false if candidate.blank?

    likes.any? { |like| like.user_id == candidate.id }
  end

  def as_json(options = {})
    super(options).merge(
      "mohs" => mohs&.to_f
    )
  end
end
