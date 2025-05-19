class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update]
  # rubocop:disable Style/SymbolArray
  def update
    if current_user.update(user_params)
      render json: {
        message: 'User updated successfully',
        user: current_user.as_json(only: [
                                     :id, :first_name, :last_name, :email, :country, :mobile_number, :unconfirmed_email
                                   ])
      }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  # rubocop:enable Style/SymbolArray

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :country, :email, :mobile_number
    )
  end
end
