Rails.application.routes.draw do
  get '/current_user', to: 'current_user#index'

  devise_for :users, path: '', path_names: {
                                 sign_in: 'login',
                                 sign_out: 'logout',
                                 registration: 'signup',
                                 confirmation: 'confirm'
                               },
                     controllers: {
                       sessions: 'users/sessions',
                       registrations: 'users/registrations',
                       confirmations: 'users/confirmations'
                     }

  put 'change_password', to: 'passwords#update'
  put '/edit_user', to: 'users#update'
  post '/upload_avatar', to: 'users#upload_avatar'

  resources :courses do
    member do
      patch :upload_image  # matches controller action name and HTTP verb
    end
  end
end
