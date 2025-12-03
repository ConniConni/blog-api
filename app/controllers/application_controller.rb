class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def authenticate_user!
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ')[1], ENV['DEVISE_JWT_SECRET_KEY']).first
      @current_user_id = jwt_payload['sub']
      @current_user = User.find(@current_user_id)
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
    render json: { error: 'Unauthorized' }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
