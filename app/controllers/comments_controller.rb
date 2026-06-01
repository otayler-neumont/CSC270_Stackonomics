# Comments on a specimen ("where did you get this?"). Login required for both
# actions (the default Authentication before_action handles that). Persistence
# goes through CommentRepository; a comment can be removed by its author or by
# the specimen's owner.
class CommentsController < ApplicationController
  before_action :set_specimen

  def create
    CommentRepository.create(specimen: @specimen, user: current_user, body: comment_params[:body])
    redirect_to specimen_path(@specimen, anchor: "comments"), notice: "Comment posted."
  rescue ActiveRecord::RecordInvalid
    redirect_to specimen_path(@specimen, anchor: "comments"), alert: "Your comment can't be blank."
  end

  def destroy
    comment = @specimen.comments.find(params[:id])

    if comment.editable_by?(current_user)
      CommentRepository.destroy(comment)
      redirect_to specimen_path(@specimen, anchor: "comments"), notice: "Comment removed.", status: :see_other
    else
      redirect_to specimen_path(@specimen, anchor: "comments"), alert: "You can't remove that comment.", status: :see_other
    end
  end

  private

  def set_specimen
    @specimen = Specimen.find(params[:specimen_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
