# frozen_string_literal: true

RailsAdmin.config do |config|
  config.asset_source = :sprockets
  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit
  config.authorize_with do
    unless current_user&.admin?
      flash[:alert] = t('application.not_authorized')
      redirect_to main_app.root_path
    end
  end

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.model 'CodeOcean::File' do
    list { limited_pagination true }
  end

  config.actions do
    # mandatory
    dashboard do
      statistics false
    end
    index # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  # stolen from https://github.com/kaminari/kaminari/issues/162#issuecomment-52083985
  if defined?(WillPaginate)
    module WillPaginate
      module ActiveRecord
        module RelationMethods
          def per(value = nil)
            per_page(value)
          end

          def total_count
            count
          end

          def first_page?
            self == first
          end

          def last_page?
            self == last
          end
        end
      end

      module CollectionMethods
        alias num_pages total_pages
      end
    end
  end
end
