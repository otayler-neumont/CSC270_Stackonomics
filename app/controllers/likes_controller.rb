# Like / unlike a specimen. Login required (default Authentication
# before_action). A singular nested resource: POST creates the like, DELETE
# removes it. Both are idempotent thanks to LikeRepository + the unique index.
class LikesController < ApplicationController
  before_action :set_specimen

  def create
    LikeRepository.like(specimen: @specimen, user: current_user)
    redirect_back fallback_location: specimen_path(@specimen)
  end

  def destroy
    LikeRepository.unlike(specimen: @specimen, user: current_user)
    redirect_back fallback_location: specimen_path(@specimen)
  end

  private

  def set_specimen
    @specimen = Specimen.find(params[:specimen_id])
  end
end
