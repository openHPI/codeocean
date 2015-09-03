FILENAME_REGEXP = /[\w\.]+/ unless Kernel.const_defined?(:FILENAME_REGEXP)

Rails.application.routes.draw do
  resources :request_for_comments
    get '/my_request_for_comments', as: 'my_request_for_comments', to: 'request_for_comments#get_my_comment_requests'
  resources :comments, except: [:destroy] do
    collection do
      delete :destroy
    end
  end

  delete '/comment_by_id', to: 'comments#destroy_by_id'
  put '/comments', to: 'comments#update'

  root to: 'application#welcome'

  namespace :admin do
    get 'dashboard', to: 'dashboard#show'
  end

  get '/help', to: 'application#help'

  resources :consumers

  resources :execution_environments do
    member do
      get :shell
      post 'shell', as: :execute_command, to: :execute_command
    end

    resources :errors, only: [:create, :index, :show]
    resources :hints
  end

  resources :exercises do
    collection do
      match '', to: 'exercises#batch_update', via: [:patch, :put]
    end

    member do
      post :clone
      get :implement
      get :statistics
      get :reload
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
      match 'activate', to: 'internal_users#activate', via: [:get, :patch, :put]
      match 'reset_password', to: 'internal_users#reset_password', via: [:get, :patch, :put]
    end
  end

  match '/forgot_password', as: 'forgot_password', to: 'internal_users#forgot_password', via: [:get, :post]

  resources :sessions, only: [:create, :destroy, :new]

  post '/lti/launch', as: 'lti_launch', to: 'sessions#create_through_lti'
  get '/lti/return', as: 'lti_return', to: 'sessions#destroy_through_lti'
  get '/sign_in', as: 'sign_in', to: 'sessions#new'
  delete '/sign_out', as: 'sign_out', to: 'sessions#destroy'

  resources :submissions, only: [:create, :index, :show] do
    member do
      get 'download/:filename', as: :download, constraints: {filename: FILENAME_REGEXP}, to: :download_file
      get 'render/:filename', as: :render, constraints: {filename: FILENAME_REGEXP}, to: :render_file
      get 'run/:filename', as: :run, constraints: {filename: FILENAME_REGEXP}, to: :run
      get :score
      get :statistics
      post :stop
      get 'test/:filename', as: :test, constraints: {filename: FILENAME_REGEXP}, to: :test
    end
  end

  resources :teams
end
