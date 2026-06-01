# Data Access Layer (DAL) for Specimen records.
#
# Errors are intentionally NOT rescued here -- the existing
# `Api::BaseController` already has `rescue_from ActiveRecord::RecordNotFound`
# and `rescue_from ActiveRecord::RecordInvalid` handlers that turn them
# into clean JSON responses. Letting the exceptions bubble up keeps the
# DAL thin and the HTTP layer in charge of HTTP concerns.
module SpecimenRepository
  module_function

  # GET /api/specimens  -> SpecimenRepository.all
  def all
    Specimen.order(:name)
  end

  # Index-friendly variant: eager-loads owner + likes/comments so the
  # collection grid doesn't fire N+1 queries rendering badges and counts.
  def all_with_associations
    Specimen.includes(:user, :likes, :comments).order(:name)
  end

  # Specimens owned by a given user (their "collection"), newest first.
  def for_user(user)
    Specimen.includes(:user, :likes, :comments).for_user(user).order(created_at: :desc)
  end

  # GET /api/specimens/:id  -> SpecimenRepository.find(id)
  # Raises ActiveRecord::RecordNotFound when no row matches.
  def find(id)
    Specimen.find(id)
  end

  # Detail page needs the owner and the full comment thread (with each
  # comment's author) plus likers; eager-load them in one place.
  def find_with_associations(id)
    Specimen.includes(:user, :likes, comments: :user).find(id)
  end

  # POST /api/specimens  -> SpecimenRepository.create(attrs)
  # Raises ActiveRecord::RecordInvalid on validation failure.
  def create(attrs)
    Specimen.create!(attrs)
  end

  # PATCH/PUT /api/specimens/:id  -> SpecimenRepository.update(id, attrs)
  # Raises RecordNotFound (bad id) or RecordInvalid (bad attrs).
  def update(id, attrs)
    record = find(id)
    record.update!(attrs)
    record
  end

  # DELETE /api/specimens/:id  -> SpecimenRepository.destroy(id)
  def destroy(id)
    find(id).destroy!
  end

  # Convenience reader used by anything that just wants the row count
  # (e.g. an "X specimens in the collection" badge in views).
  def count
    Specimen.count
  end
end
