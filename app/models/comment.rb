class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :specimen

  validates :body, presence: true, length: { maximum: 1000 }

  def editable_by?(candidate)
    candidate.present? && (user_id == candidate.id || specimen.owned_by?(candidate))
  end
end
