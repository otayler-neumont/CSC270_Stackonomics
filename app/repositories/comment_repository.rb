# Data Access Layer (DAL) for Comment records, mirroring SpecimenRepository.
# HTTP concerns (status codes, auth) stay in the controller; persistence and
# query construction live here.
module CommentRepository
  module_function

  # Comments for a specimen, oldest first, with authors eager-loaded.
  def for_specimen(specimen)
    specimen.comments.includes(:user).order(created_at: :asc)
  end

  # Create a comment authored by `user` on `specimen`.
  # Raises ActiveRecord::RecordInvalid on validation failure (blank body).
  def create(specimen:, user:, body:)
    specimen.comments.create!(user: user, body: body)
  end

  def find(id)
    Comment.find(id)
  end

  def destroy(comment)
    comment.destroy!
  end
end
