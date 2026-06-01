# Server-rendered specimen UI (Phase 5). Reads go through SpecimenRepository
# (the Phase 4 DAL); writes build through the current_user association so a
# specimen is always owned by whoever created it. Browsing is public; any
# mutation requires login, and edit/delete additionally require ownership.
class SpecimensController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_specimen, only: %i[edit update destroy delete_confirm]
  before_action :require_owner!, only: %i[edit update destroy delete_confirm]

  def index
    @scope = params[:scope]
    @specimens =
      if @scope == "mine" && current_user
        SpecimenRepository.for_user(current_user)
      else
        SpecimenRepository.all_with_associations
      end
  end

  def show
    @specimen = SpecimenRepository.find_with_associations(params[:id])
  end

  def new
    @specimen = current_user.specimens.new(tint: "slate")
  end

  def create
    @specimen = current_user.specimens.new(specimen_params)

    if @specimen.save
      redirect_to @specimen, notice: "\u201C#{@specimen.name}\u201D added to your collection."
    else
      flash.now[:alert] = @specimen.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @specimen.update(specimen_params)
      redirect_to @specimen, notice: "\u201C#{@specimen.name}\u201D updated."
    else
      flash.now[:alert] = @specimen.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @specimen.destroy
    redirect_to specimens_path(scope: "mine"),
                notice: "Specimen removed from your collection.", status: :see_other
  end

  def delete_confirm
  end

  private

  def set_specimen
    @specimen = Specimen.find(params[:id])
  end

  def require_owner!
    return if @specimen.owned_by?(current_user)

    redirect_to @specimen, alert: "You can only edit specimens in your own collection."
  end

  def specimen_params
    permitted = params.require(:specimen).permit(:name, :color, :mohs, :origin, :fact, :tint)
    permitted[:mohs] = nil if permitted[:mohs].blank?
    permitted
  end
end
