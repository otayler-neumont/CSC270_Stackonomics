module Api
  # All persistence goes through SpecimenRepository (the Phase 4 DAL).
  # This controller is now responsible only for HTTP concerns:
  # parsing params, choosing a status code, and rendering JSON.
  # Any time you'd reach for Specimen.<something> here, add it to the
  # repository instead.
  class SpecimensController < BaseController
    # GET /api/specimens  ->  SpecimenRepository.all
    def index
      render json: SpecimenRepository.all
    end

    # GET /api/specimens/:id  ->  SpecimenRepository.find(id)
    def show
      render json: SpecimenRepository.find(params[:id])
    end

    # POST /api/specimens  ->  SpecimenRepository.create(attrs)
    def create
      specimen = SpecimenRepository.create(specimen_params)
      render json: specimen, status: :created
    end

    # PATCH/PUT /api/specimens/:id  ->  SpecimenRepository.update(id, attrs)
    def update
      specimen = SpecimenRepository.update(params[:id], specimen_params)
      render json: specimen
    end

    # DELETE /api/specimens/:id  ->  SpecimenRepository.destroy(id)
    def destroy
      SpecimenRepository.destroy(params[:id])
      head :no_content
    end

    private

    def specimen_params
      permitted = params.require(:specimen).permit(:name, :color, :mohs, :origin, :fact, :tint)
      permitted[:mohs] = nil if permitted[:mohs].blank?
      permitted
    end
  end
end
