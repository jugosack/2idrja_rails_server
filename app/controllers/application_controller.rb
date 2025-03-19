class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user_from_token!

  rescue_from JWT::DecodeError, with: :handle_unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :handle_unauthorized

  protected

  # Devise parameter sanitization
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: %i[first_name last_name country mobile_number terms_of_use])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name country mobile_number])
  end

  # Authenticate user from JWT token
  def authenticate_user_from_token!
    auth_header = request.headers['Authorization']
    if auth_header.present?
      token = auth_header.split(' ').last
      decoded_token = decode_jwt_token(token)
  
      if decoded_token
        Rails.logger.info "Decoded Token: #{decoded_token}"
        user_id = decoded_token[0]['sub']  # Extract user ID using 'sub'
        Rails.logger.info "Extracted User ID: #{user_id}"
        @current_user = User.find_by(id: user_id)
        Rails.logger.info "Current User in authenticate_user_from_token!: #{@current_user.inspect}"  # Log the current user
      end
    end
  
    # Render unauthorized if no valid user is found
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  # Decode JWT token
  def decode_jwt_token(token)
    secret_key = Rails.application.credentials.fetch(:secret_key_base)
    algorithm = 'HS256'

    begin
      JWT.decode(token, secret_key, true, algorithm: algorithm)
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      nil
    end
  end

  # Handle unauthorized access
  def handle_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  # Expose current_user to controllers
  attr_reader :current_user
end