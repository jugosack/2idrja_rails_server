class Users::SessionsController < Devise::SessionsController
  include RackSessionFix
  before_action :authenticate_user_from_token!, only: [:destroy]

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user_from_token!, only: [:create] # Skip authentication for login

  respond_to :json

  def create
  user = User.find_by(email: params[:user][:email]&.downcase)

  if user.nil?
    Rails.logger.info "Login failed: user not found"
    return render json: {
      status: { code: 401, message: 'Invalid email or password' }
    }, status: :unauthorized
  end

  unless user.valid_password?(params[:user][:password])
    Rails.logger.info "Login failed: invalid password for #{user.email}"
    return render json: {
      status: { code: 401, message: 'Invalid email or password' }
    }, status: :unauthorized
  end

  unless user.confirmed?
    Rails.logger.info "Login blocked: email not confirmed for #{user.email}"
    return render json: {
      status: { code: 401, message: 'You must confirm your email address before logging in.' }
    }, status: :unauthorized
  end

  sign_in(user)
  respond_with(user)
end


  private

  def respond_with(resource, _opts = {})
    if resource.active_for_authentication?
      token = generate_jwt_token(resource)
      render json: {
        status: { code: 200, message: 'Logged in successfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
        token: token
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: 'You have to confirm your email address before continuing.' }
      }, status: :unauthorized
    end
  end

  def respond_to_on_destroy
    auth_header = request.headers['Authorization']
    if auth_header.blank?
      Rails.logger.error 'Authorization header missing'
      return render json: { status: 401, message: 'Authorization header missing' }, status: :unauthorized
    end

    token = auth_header.split.last
    decoded_token = decode_jwt_token(token)

    if decoded_token.nil? # rubocop:disable Style/IfUnlessModifier
      return render json: { status: 401, message: 'Invalid token' }, status: :unauthorized
    end

    user_id = decoded_token[0]['sub']
    user = User.find_by(id: user_id)

    if user
      user.update(jti: SecureRandom.uuid) # Invalidate the token
      render json: { status: 200, message: 'Logged out successfully' }, status: :ok
    else
      render json: { status: 401, message: "Couldn't find an active session." }, status: :unauthorized
    end
  end

  def generate_jwt_token(user)
    payload = {
      sub: user.id, # Symbol key
      jti: user.jti,       # Required for revocation
      exp: 24.hours.from_now.to_i,
      scp: 'user'          # Required by warden-jwt_auth
    }
    Rails.logger.info "Generated Token Payload: #{payload}"
    JWT.encode(payload, Rails.application.credentials.fetch(:secret_key_base), 'HS256')
  end

  # Reuse the decode_jwt_token method from ApplicationController
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
end
