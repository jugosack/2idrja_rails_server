# class UsersController < ApplicationController
#   before_action :authenticate_user!
#   skip_before_action :verify_authenticity_token, only: [:update, :upload_avatar]

#   def upload_avatar
#     if params[:avatar].present?
#       current_user.avatar.purge if current_user.avatar.attached?
#       current_user.avatar.attach(params[:avatar])
#       if current_user.save
#         render json: {
#           message: 'Avatar uploaded successfully',
#           avatar_url: url_for(current_user.avatar)
#         }, status: :ok
#       else
#         render json: { error: 'Failed to save avatar' }, status: :unprocessable_entity
#       end
#     else
#       render json: { error: 'No avatar file provided' }, status: :bad_request
#     end
#   end

#
#   def update
#     if current_user.update(user_params)
#       render json: {
#         message: 'User updated successfully',
#         user: current_user.as_json(only: [
#                                      :id, :first_name, :last_name, :email, :country, :mobile_number, :unconfirmed_email, :role
#                                    ])
#       }, status: :ok
#     else
#       render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
#     end
#   end
#   #   private

#   def user_params
#     params.require(:user).permit(
#       :first_name, :last_name, :country, :email, :mobile_number
#     )
#   end
# end
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!, only: %i[create index destroy admin_update]
  skip_before_action :verify_authenticity_token, only: %i[create update upload_avatar destroy admin_update]

  def index
    users = User.all
    render json: users.as_json(only: %i[id email first_name last_name country mobile_number role])
  end

  def create
    user = User.new(user_create_params)
    if user.save
      user.send_confirmation_instructions unless user.confirmed?
      render json: {
        message: 'User created successfully',
        user: user.as_json(only: %i[id email first_name last_name role])
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find_by(id: params[:id])
    if user.nil?
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    if user.destroy
      render json: { message: 'User deleted successfully' }, status: :ok
    else
      render json: { error: 'Failed to delete user' }, status: :unprocessable_entity
    end
  end

  def update
    if current_user.update(user_params)
      render json: {
        message: 'User updated successfully',
        user: current_user.as_json(only: %i[
                                     id first_name last_name email country mobile_number unconfirmed_email role
                                   ])
      }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Admin updates any user by ID
  def admin_update
    user = User.find_by(id: params[:id])
    if user.nil?
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    if user.update(user_params)
      render json: {
        message: 'User updated successfully',
        user: user.as_json(only: %i[
                             id first_name last_name email country mobile_number unconfirmed_email role
                           ])
      }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

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

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :country, :email, :mobile_number, :role
    )
  end

  def user_create_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      :first_name, :last_name, :country, :mobile_number, :role
    )
  end

  def authorize_admin!
    render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user.role == 'admin'
  end
end
