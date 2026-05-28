# Data Access Layer (DAL) for Specimen records.
#
# Phase 4 of the assignment asks for a layer between the controllers and
# the database. In a Rails app, ActiveRecord already plays that role, but
# the rubric calls for an explicit, named DAL that controllers go through,
# so this module is that layer. The rule across the codebase is:
#
#     Controllers MUST NOT call `Specimen.<anything>` directly.
#     Anything that needs to read or write specimens calls
#     SpecimenRepository.<method> instead.
#
# Keeping persistence in one place makes it cheap later to add caching,
# swap the backing store, or wrap every query in instrumentation without
# touching the controllers.
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

  # GET /api/specimens/:id  -> SpecimenRepository.find(id)
  # Raises ActiveRecord::RecordNotFound when no row matches.
  def find(id)
    Specimen.find(id)
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
