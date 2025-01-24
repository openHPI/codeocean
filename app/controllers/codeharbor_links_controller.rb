# frozen_string_literal: true

class CodeharborLinksController < ApplicationController
  include CommonBehavior
  before_action :verify_codeharbor_activation
  before_action :set_codeharbor_link, only: %i[edit update destroy]
  before_action :set_user_and_authorize

  def new
    base_url = CodeOcean::Config.new(:code_ocean).read[:codeharbor][:url] || ''
    @codeharbor_link = CodeharborLink.new(
      push_url: "#{base_url}/import_task",
      check_uuid_url: "#{base_url}/import_uuid_check",
      user: @user
    )
    authorize!
  end

  def edit
    authorize!
  end

  def create
    @codeharbor_link = CodeharborLink.new(codeharbor_link_params)
    @codeharbor_link.user = @user
    authorize!
    create_and_respond(object: @codeharbor_link, path: -> { @user })
  end

  def update
    authorize!
    update_and_respond(object: @codeharbor_link, params: codeharbor_link_params, path: @user)
  end

  def destroy
    destroy_and_respond(object: @codeharbor_link, path: @user)
  end

  private

  def authorize!
    raise Pundit::NotAuthorizedError if @codeharbor_link.present? && @user.present? && @codeharbor_link.user != @user

    authorize(@codeharbor_link)
  end

  def verify_codeharbor_activation
    raise Pundit::NotAuthorizedError unless policy(CodeharborLink).enabled?
  end

  def set_codeharbor_link
    @codeharbor_link = CodeharborLink.find(params[:id])
    authorize!
  end

  def set_user_and_authorize
    if params[:external_user_id]
      @user = ExternalUser.find(params[:external_user_id])
    else
      @user = InternalUser.find(params[:internal_user_id])
    end
    params[:user_id] = @user.id_with_type # for the breadcrumbs
    authorize(@user, :change_codeharbor_link?)
  end

  def codeharbor_link_params
    params.expect(codeharbor_link: %i[push_url check_uuid_url api_key])
  end
end
