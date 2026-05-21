module Api
  class SpecimensController < BaseController
    before_action :set_specimen, only: %i[show update destroy]

    # GET /api/specimens
    def index
      specimens = Specimen.order(:name)
      render json: specimens
    end

    # GET /api/specimens/:id
    def show
      render json: @specimen
    end

    # POST /api/specimens
    def create
      specimen = Specimen.create!(specimen_params)
      render json: specimen, status: :created
    end

    # PATCH/PUT /api/specimens/:id
    def update
      @specimen.update!(specimen_params)
      render json: @specimen
    end

    # DELETE /api/specimens/:id
    def destroy
      @specimen.destroy!
      head :no_content
    end

    private

    def set_specimen
      @specimen = Specimen.find(params[:id])
    end

    def specimen_params
      permitted = params.require(:specimen).permit(:name, :color, :mohs, :origin, :fact, :tint)
      permitted[:mohs] = nil if permitted[:mohs].blank?
      permitted
    end
  end
end
