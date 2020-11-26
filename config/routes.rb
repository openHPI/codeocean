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
  resources :codeharbor_links, only: %i[new create edit update destroy]
  resources :request_for_comments, except: %i[edit destroy] do
    member do
      get :mark_as_solved, defaults: { format: :json }
      post :set_thank_you_note, defaults: { format: :json }
    end
  end
  resources :comments, defaults: { format: :json }
  get '/my_request_for_comments', as: 'my_request_for_comments', to: 'request_for_comments#get_my_comment_requests'
  get '/my_rfc_activity', as: 'my_rfc_activity', to: 'request_for_comments#get_rfcs_with_my_comments'

  delete '/comment_by_id', to: 'comments#destroy_by_id'
  put '/comments', to: 'comments#update', defaults: { format: :json }

  resources :subscriptions, only: [:create, :destroy] do
    member do
      get :unsubscribe, to: 'subscriptions#destroy'
    end
  end

  root to: 'application#welcome'

  namespace :admin do
    get 'dashboard', to: 'dashboard#show'
    get 'dashboard/dump_docker', to: 'dashboard#dump_docker'
  end

  get '/insights', to: 'flowr#insights'

  get 'statistics/', to: 'statistics#show'
  get 'statistics/graphs', to: 'statistics#graphs'
  get 'statistics/graphs/user-activity', to: 'statistics#user_activity'
  get 'statistics/graphs/user-activity-history', to: 'statistics#user_activity_history'
  get 'statistics/graphs/rfc-activity', to: 'statistics#rfc_activity'
  get 'statistics/graphs/rfc-activity-history', to: 'statistics#rfc_activity_history'

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
  end

  post '/import_exercise' => 'exercises#import_exercise'
  post '/import_uuid_check' => 'exercises#import_uuid_check'

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
      get :requests_for_comments
      get :reload
      post :submit
      get 'study_group_dashboard/:study_group_id', to: 'exercises#study_group_dashboard'
      post :export_external_check
      post :export_external_confirm
    end
  end

  resources :exercise_collections do
    member do
      get :statistics
    end
  end

  resources :proxy_exercises do
    member do
      post :clone
      get :reload
    end
  end

  resources :tags

  resources :tips

  resources :user_exercise_feedbacks, except: [:show, :index]

  resources :external_users, only: [:index, :show], concerns: :statistics do
    resources :exercises, concerns: :statistics
    member do
      get :tag_statistics
    end
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
  match '/sign_out', as: 'sign_out', to: 'sessions#destroy', via: [:get, :delete]

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

  resources :study_groups, only: [:index, :show, :edit, :destroy, :update]

  resources :events, only: [:create]

  post "/evaluate", to: 'remote_evaluation#evaluate', via: [:post]
  post "/submit", to: 'remote_evaluation#submit', via: [:post]

  mount ActionCable.server => '/cable'
  mount RailsAdmin::Engine => '/rails_admin', as: 'rails_admin'
end
