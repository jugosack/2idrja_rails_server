class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update, :upload_avatar] # rubocop:disable Style/SymbolArray

  def upload_avatar
    if params[:avatar].present?
      current_user.avatar.purge if current_user.avatar.attached?
      current_user.avatar.attach(params[:avatar])
      if current_user.save
        render json: {
          message: 'Avatar uploaded successfully',
          avatar_url: url_for(current_user.avatar)
        }, status: :ok
      else
        render json: { error: 'Failed to save avatar' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No avatar file provided' }, status: :bad_request
    end
  end

  # rubocop:disable Style/SymbolArray
  def update
    if current_user.update(user_params)
      render json: {
        message: 'User updated successfully',
        user: current_user.as_json(only: [
                                     :id, :first_name, :last_name, :email, :country, :mobile_number, :unconfirmed_email, :role
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
