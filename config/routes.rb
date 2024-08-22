# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

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
  get '/exercises/:exercise_id/request_for_comments', as: 'exercise_request_for_comments', to: 'request_for_comments#rfcs_for_exercise'

  delete '/comment_by_id', to: 'comments#destroy_by_id'
  put '/comments', to: 'comments#update', defaults: {format: :json}

  resources :subscriptions, only: %i[create destroy] do
    member do
      get :unsubscribe, to: 'subscriptions#destroy'
    end
  end

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
      get 'download/*filename', as: :download_file_from, action: :download_arbitrary_file, controller: 'live_streams', format: false # Admin file-system access to runners
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
      get :statistics
      get :feedback, path: 'feedbacks'
      get :reload
      get 'study_group_dashboard/:study_group_id', to: 'exercises#study_group_dashboard'
      post :export_external_check
      post :export_external_confirm
    end

    resources :programming_groups
    resources :user_exercise_feedbacks, except: %i[show index], path: 'feedbacks'
  end

  resources :programming_groups, except: %i[new create]

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

  resources :external_users, only: %i[index show], concerns: :statistics do
    resources :exercises, only: [] do
      get :statistics, to: 'exercises#external_user_statistics', on: :member
    end
    member do
      get :tag_statistics
    end
  end

  namespace :code_ocean do
    resources :files, only: %i[create destroy]
  end
  get '/uploads/files/:id/*filename', to: 'code_ocean/files#show_protected_upload', as: :protected_upload, format: false # View file, e.g., when implementing or viewing an exercise
  get '/uploads/render_files/:id/*filename', to: 'code_ocean/files#render_protected_upload', as: :render_protected_upload, format: false # Render action with embedded files, i.e., images in user-created HTML

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
      get 'download', as: :download, action: :download # Full submission download with RemoteEvaluationMapping
      get 'download/*filename', as: :download_file, action: :download_file, format: false # Single file download, currently not used in the frontend (but working)
      get 'download_stream/*filename', as: :download_stream_file, action: :download_submission_file, controller: 'live_streams', format: false # Access runner artifacts
      get 'render/*filename', as: :render, action: :render_file, format: false
      get 'run/*filename', as: :run, action: :run, format: false
      get :score
      get :statistics
      get 'test/*filename', as: :test, action: :test, format: false
      get :finalize
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

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up', to: 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get 'service-worker', to: 'rails/pwa#service_worker', as: :pwa_service_worker, defaults: {format: :js}
  get 'manifest', to: 'rails/pwa#manifest', as: :pwa_manifest, defaults: {format: :webmanifest}

  # Defines the root path route ("/")
  root to: 'application#welcome'
end
