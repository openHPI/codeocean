FILENAME_REGEXP = /[\w\.]+/ unless Kernel.const_defined?(:FILENAME_REGEXP)

Rails.application.routes.draw do
  root 'application#welcome'

  namespace :admin do
    get 'dashboard' => 'dashboard#show'
  end

  get '/help' => 'application#help'

  resources :consumers

  resources :execution_environments do
    member do
      get :shell
      post 'shell' => :execute_command, as: :execute_command
    end

    resources :errors, only: [:create, :index, :show]
    resources :hints
  end

  resources :exercises do
    member do
      post :clone
      get :implement
      get :statistics
      post :submit
    end
  end

  resources :external_users, only: [:index, :show]

  namespace :code_ocean do
    resources :files, only: [:create, :destroy]
  end

  resources :file_types

  resources :internal_users do
    member do
      match 'activate' => 'internal_users#activate', via: [:get, :patch, :put]
      match 'reset_password' => 'internal_users#reset_password', via: [:get, :patch, :put]
    end
  end

  match '/forgot_password' => 'internal_users#forgot_password', as: 'forgot_password', via: [:get, :post]

  resources :sessions, only: [:create, :destroy, :new]

  post '/lti/launch' => 'sessions#create_through_lti', as: 'lti_launch'
  get '/lti/return' => 'sessions#destroy_through_lti', as: 'lti_return'
  get '/sign_in' => 'sessions#new', as: 'sign_in'
  delete '/sign_out' => 'sessions#destroy', as: 'sign_out'

  resources :submissions, only: [:create, :index, :show] do
    member do
      get 'download/:filename' => :download_file, as: :download, constraints: {filename: FILENAME_REGEXP}
      get 'render/:filename' => :render_file, as: :render, constraints: {filename: FILENAME_REGEXP}
      get 'run/:filename' => :run, as: :run, constraints: {filename: FILENAME_REGEXP}
      get :score
      get :statistics
      post :stop
      get 'test/:filename' => :test, as: :test, constraints: {filename: FILENAME_REGEXP}
    end
  end

  resources :teams
end
