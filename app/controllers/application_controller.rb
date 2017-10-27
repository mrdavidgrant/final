class ApplicationController < ActionController::API
  # before_action :authenticate_request
  respond_to :json
  attr_reader :current_user

  def null_response
    render body: nil, status: 404
  end

  private

  def authenticate_request
    @current_user = AuthorizeApiRequest.call(request.headers).result
    render json: { error: 'Not Authorized' }, status: 401 unless @current_user
  end

  def jwt_encode(payload, exp = 48.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def jwt_decode(token)
    body = JWT.decode(token, Rails.application.secrets.secret_key_base)[0]
    HashWithIndifferentAccess.new body
  rescue
    nil
  end
end
