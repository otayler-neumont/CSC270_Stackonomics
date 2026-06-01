class Like < ApplicationRecord
  belongs_to :user
  belongs_to :specimen

  validates :user_id, uniqueness: { scope: :specimen_id }
end
