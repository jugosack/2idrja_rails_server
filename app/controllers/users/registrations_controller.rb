class Users::RegistrationsController < Devise::RegistrationsController
  include RackSessionFix
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user_from_token!, only: [:create]

  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if request.method == 'POST' && resource.persisted?
      render json: {
        status: { code: 200, message: 'Signed up sucessfully.' },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }, status: :ok
    elsif request.method == 'DELETE'
      render json: {
        status: { code: 200, message: 'Account deleted successfully.' }
      }, status: :ok
    else
      render json: {
        status: { code: 422, message: "User couldn't be created successfully." \
                                      "#{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end
end
