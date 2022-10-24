# frozen_string_literal: true

class TipsController < ApplicationController
  include CommonBehavior

  before_action :set_tip, only: MEMBER_ACTIONS
  before_action :set_file_types, only: %i[create edit new update]

  def authorize!
    authorize(@tip || @tips)
  end
  private :authorize!

  def index
    @tips = Tip.all.paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    @tip = Tip.new
    authorize!
  end

  def tip_params
    return if params[:tip].blank?

    params[:tip]
      .permit(:title, :description, :example, :file_type_id)
      .each {|_key, value| value.strip! unless value.is_a?(Array) }
      .merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :tip_params

  def edit; end

  def create
    @tip = Tip.new(tip_params)
    authorize!
    create_and_respond(object: @tip)
  end

  def set_tip
    @tip = Tip.find(params[:id])
    authorize!
  end
  private :set_tip

  def update
    update_and_respond(object: @tip, params: tip_params)
  end

  def destroy
    destroy_and_respond(object: @tip)
  end

  def set_file_types
    @file_types = FileType.all.order(:name)
  end
  private :set_file_types
end
