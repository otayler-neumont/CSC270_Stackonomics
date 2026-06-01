# Data Access Layer (DAL) for Like records, mirroring SpecimenRepository.
# Likes are a toggle: a (user, specimen) pair either exists or it doesn't.
module LikeRepository
  module_function

  # Idempotent "like": returns the existing like or creates one. The unique
  # index on [user_id, specimen_id] is the real guard against duplicates.
  def like(specimen:, user:)
    specimen.likes.find_or_create_by!(user: user)
  end

  # Idempotent "unlike": removes the pair if present, no-op otherwise.
  def unlike(specimen:, user:)
    specimen.likes.where(user: user).destroy_all
  end

  def liked?(specimen:, user:)
    return false if user.blank?

    specimen.likes.exists?(user: user)
  end

  def count_for(specimen)
    specimen.likes.count
  end
end
