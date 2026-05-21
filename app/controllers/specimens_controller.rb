# HTML shells for Phase 3. Data is loaded and mutated via /api/specimens (see views).
class SpecimensController < ApplicationController
  def index
    flash.now[:notice] = "Specimen removed from the collection." if params[:deleted].present?
  end

  def show
    @specimen_id = params[:id]
  end

  def new
  end

  def edit
    @specimen_id = params[:id]
  end

  def delete_confirm
    @specimen_id = params[:id]
  end
end
