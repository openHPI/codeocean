# frozen_string_literal: true

FILENAME_REGEXP = /.+/ unless Kernel.const_defined?(:FILENAME_REGEXP)

Rails.application.routes.draw do
  resources :community_solutions, only: %i[index edit update]
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
      get :mark_as_solved, defaults: {format: :json}
      post :set_thank_you_note, defaults: {format: :json}
      post :clear_question
    end
  end
  resources :comments, defaults: {format: :json}
  get '/my_request_for_comments', as: 'my_request_for_comments', to: 'request_for_comments#my_comment_requests'
  get '/my_rfc_activity', as: 'my_rfc_activity', to: 'request_for_comments#rfcs_with_my_comments'
  get '/exercises/:exercise_id/request_for_comments', as: 'rfcs_for_exercise', to: 'request_for_comments#rfcs_for_exercise'

  delete '/comment_by_id', to: 'comments#destroy_by_id'
  put '/comments', to: 'comments#update', defaults: {format: :json}

  resources :subscriptions, only: %i[create destroy] do
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
      get :list_files, as: :list_files_in
      get 'download/:filename', as: :download_file_from, constraints: {filename: FILENAME_REGEXP}, action: :download_arbitrary_file, controller: 'live_streams'
      get :statistics
      post :sync_to_runner_management
    end

    post :sync_all_to_runner_management, on: :collection
  end

  post '/import_task' => 'exercises#import_task'
  post '/import_uuid_check' => 'exercises#import_uuid_check'

  resources :exercises do
    collection do
      match '', to: 'exercises#batch_update', via: %i[patch put]
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

  resources :user_exercise_feedbacks, except: %i[show index]

  resources :external_users, only: %i[index show], concerns: :statistics do
    resources :exercises do
      get :statistics, to: 'exercises#external_user_statistics', on: :member
    end
    member do
      get :tag_statistics
    end
  end

  namespace :code_ocean do
    resources :files, only: %i[create destroy]
  end
  get '/uploads/files/:id/:filename', to: 'code_ocean/files#show_protected_upload', as: :protected_upload, constraints: {filename: FILENAME_REGEXP}
  get '/uploads/render_files/:id/:filename', to: 'code_ocean/files#render_protected_upload', as: :render_protected_upload, constraints: {filename: FILENAME_REGEXP}

  resources :file_types

  resources :internal_users do
    member do
      match 'activate', to: 'internal_users#activate', via: %i[get patch put]
      match 'reset_password', to: 'internal_users#reset_password', via: %i[get patch put]
    end
  end

  match '/forgot_password', as: 'forgot_password', to: 'internal_users#forgot_password', via: %i[get post]

  resources :sessions, only: %i[create destroy new]

  post '/lti/launch', as: 'lti_launch', to: 'sessions#create_through_lti'
  get '/lti/return', as: 'lti_return', to: 'sessions#destroy_through_lti'
  get '/sign_in', as: 'sign_in', to: 'sessions#new'
  match '/sign_out', as: 'sign_out', to: 'sessions#destroy', via: %i[get delete]

  resources :submissions, only: %i[create index show] do
    member do
      get 'download', as: :download, action: :download
      get 'download/:filename', as: :download_file, constraints: {filename: FILENAME_REGEXP}, action: :download_file
      get 'download_stream/:filename', as: :download_stream_file, constraints: {filename: FILENAME_REGEXP}, action: :download_submission_file, controller: 'live_streams'
      get 'render/:filename', as: :render, constraints: {filename: FILENAME_REGEXP}, action: :render_file
      get 'run/:filename', as: :run, constraints: {filename: FILENAME_REGEXP}, action: :run
      get :score
      get :statistics
      get 'test/:filename', as: :test, constraints: {filename: FILENAME_REGEXP}, action: :test
    end
  end

  resources :study_groups, only: %i[index show edit destroy update] do
    member do
      post :set_as_current
    end
  end

  resources :events, only: [:create]

  post '/evaluate', to: 'remote_evaluation#evaluate', defaults: {format: :json}
  post '/submit', to: 'remote_evaluation#submit', defaults: {format: :json}

  resources :ping, only: :index, defaults: {format: :json}

  mount ActionCable.server => '/cable'
  mount RailsAdmin::Engine => '/rails_admin', as: 'rails_admin'
end
