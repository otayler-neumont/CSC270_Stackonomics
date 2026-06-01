module Api
  # Read-only JSON view of the collection, still served through the Phase 4
  # DAL (SpecimenRepository). All mutations moved to the authenticated,
  # ownership-aware HTML SpecimensController in Phase 5, so the API can't be
  # used to bypass the "only edit your own stuff" rule.
  class SpecimensController < BaseController
    # GET /api/specimens  ->  SpecimenRepository.all
    def index
      render json: SpecimenRepository.all
    end

    # GET /api/specimens/:id  ->  SpecimenRepository.find(id)
    def show
      render json: SpecimenRepository.find(params[:id])
    end
  end
end
