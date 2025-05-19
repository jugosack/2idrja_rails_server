class PasswordsController < ApplicationController
  before_action :authenticate_user!

  skip_before_action :verify_authenticity_token

  def update
    user = current_user

    permitted = password_params

    unless user.valid_password?(permitted[:current_password]) # rubocop:disable Style/IfUnlessModifier
      return render json: { error: 'Current password is incorrect' }, status: :unauthorized
    end

    if permitted[:new_password] != permitted[:new_password_confirmation]
      return render json: { error: 'Password confirmation does not match' }, status: :unprocessable_entity
    end

    if user.update(password: permitted[:new_password])
      render json: { message: 'Password updated successfully' }, status: :ok
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    permitted = params.permit(
      :current_password,
      :new_password,
      :new_password_confirmation,
      password: [:current_password, :new_password, :new_password_confirmation] # rubocop:disable Style/SymbolArray
    )

    # Prefer root-level keys if present, fallback to nested
    {
      current_password: permitted[:current_password] || permitted.dig(:password, :current_password),
      new_password: permitted[:new_password] || permitted.dig(:password, :new_password),
      new_password_confirmation: permitted[:new_password_confirmation] || permitted.dig(:password, :new_password_confirmation)
    }
  end
end
