FILENAME_REGEXP = /[\w\.]+/ unless Kernel.const_defined?(:FILENAME_REGEXP)

Rails.application.routes.draw do
  resources :error_template_attributes
  resources :error_templates do
    member do
      put 'attribute', to: 'error_templates#add_attribute'
      delete 'attribute', to: 'error_templates#remove_attribute'
    end
  end
  resources :file_templates do
    collection do
      get 'by_file_type/:file_type_id', as: :by_file_type, action: :by_file_type
    end
  end
  resources :code_harbor_links
  resources :request_for_comments do
    member do
      get :mark_as_solved
      post :create_comment_exercise
      post :set_thank_you_note
    end
  end
  resources :comments
  get '/my_request_for_comments', as: 'my_request_for_comments', to: 'request_for_comments#get_my_comment_requests'
  get '/my_rfc_activity', as: 'my_rfc_activity', to: 'request_for_comments#get_rfcs_with_my_comments'

  delete '/comment_by_id', to: 'comments#destroy_by_id'
  put '/comments', to: 'comments#update'

  resources :subscriptions do
    member do
      get :unsubscribe, to: 'subscriptions#destroy'
    end
  end

  root to: 'application#welcome'

  namespace :admin do
    get 'dashboard', to: 'dashboard#show'
  end

  get '/help', to: 'application#help'

  concern :statistics do
    member do
      get :statistics
    end
  end


  resources :consumers

  resources :execution_environments do
    member do
      get :shell
      post 'shell', as: :execute_command, action: :execute_command
      get :statistics
    end

    resources :errors, only: [:create, :index, :show]
    resources :hints
  end

  post '/import_proforma_xml' => 'exercises#import_proforma_xml'

  resources :exercises do
    collection do
      match '', to: 'exercises#batch_update', via: [:patch, :put]
    end

    member do
      post :clone
      get :implement
      get :working_times
      post :intervention
      post :search
      get :statistics
      get :feedback
      get :reload
      post :submit
    end
  end

  resources :exercise_collections

  resources :proxy_exercises do
    member do
      post :clone
      get :reload
      post :submit
    end
  end

  resources :tags do
    member do
      post :clone
      get :reload
      post :submit
    end
  end

  resources :user_exercise_feedbacks do
    member do
      get :reload
      post :submit
    end
  end

  resources :interventions do
    member do
      post :clone
      get :reload
      post :submit
    end
  end

  resources :external_users, only: [:index, :show], concerns: :statistics do
    resources :exercises, concerns: :statistics
  end

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
      get 'download', as: :download, action: :download
      get 'download/:filename', as: :download_file, constraints: {filename: FILENAME_REGEXP}, action: :download_file
      get 'render/:filename', as: :render, constraints: {filename: FILENAME_REGEXP}, action: :render_file
      get 'run/:filename', as: :run, constraints: {filename: FILENAME_REGEXP}, action: :run
      get :score
      get :statistics
      post :stop
      get 'test/:filename', as: :test, constraints: {filename: FILENAME_REGEXP}, action: :test
    end
  end

  post "/evaluate", to: 'remote_evaluation#evaluate', via: [:post]

end
