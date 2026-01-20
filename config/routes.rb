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

  post '/create_user', to: 'users#create'
  get '/users', to: 'users#index'
  delete '/users/:id', to: 'users#destroy'
  put '/admin/users/:id', to: 'users#admin_update'

  resources :courses do
    member do
      patch :upload_image  # matches controller action name and HTTP verb
    end
  end
  resources :instructors, only: %i[index show create update destroy]

  resources :enrollments, only: [:create]

  post '/payments/create_payment_intent', to: 'payments#create_payment_intent'
  post '/payments/confirm', to: 'payments#confirm'
  post '/payments/webhook', to: 'payments#webhook'

  get '/users/:user_id/enrolled_courses', to: 'courses#enrolled_courses'

  resources :reviews, only: %i[create index]
end
