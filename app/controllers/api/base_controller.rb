module Api
  class BaseController < ActionController::API
    include ActionController::MimeResponds

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Not found" }, status: :not_found
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
