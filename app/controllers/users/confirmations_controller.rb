# app/controllers/users/confirmations_controller.rb
class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_before_action :authenticate_user_from_token!, only: [:show]

  # Dodavanje show akcije koja samo preusmerava na željeni URL
  # def show
  #   self.resource = resource_class.confirm_by_token(params[:confirmation_token])
  #   yield resource if block_given?
  #   if resource.errors.empty?
  #     # Ako je potvrda uspešna, preusmeravamo na željeni URL
  #     redirect_to 'http://localhost:3001/login'
  #   else
  #     # Ako ima grešaka, možete ih obraditi na odgovarajući način
  #     respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
  #   end
  # end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?
    if resource.errors.empty?
      redirect_to 'http://localhost:3001/login'
    else
      # Instead of respond_with_navigational try this:
      flash[:alert] = resource.errors.full_messages.join(', ')
      redirect_to 'http://localhost:3001/login' # or some error page
    end
  end
  

  private

  def after_confirmation_path_for(_resource_name, _resource)
    'http://localhost:3001/login'
  end
end
