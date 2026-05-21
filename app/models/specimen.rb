class Specimen < ApplicationRecord
  TINTS = %w[slate rose blue emerald fuchsia purple sky cyan indigo red pink teal].freeze

  validates :name, presence: true
  validates :mohs, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
  validates :tint, inclusion: { in: TINTS }, allow_nil: true

  def as_json(options = {})
    super(options).merge(
      "mohs" => mohs&.to_f
    )
  end
end
