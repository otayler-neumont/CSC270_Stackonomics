# A user's public profile is their collection. Browsing is open to everyone
# (logged in or not); only the owner sees management affordances, enforced in
# the specimen controllers rather than here.
class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[show]

  def show
    @user = User.find(params[:id])
    @specimens = SpecimenRepository.for_user(@user)
  end
end
