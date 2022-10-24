# frozen_string_literal: true

class TagsController < ApplicationController
  include CommonBehavior

  before_action :set_tag, only: MEMBER_ACTIONS

  def authorize!
    authorize(@tag || @tags)
  end
  private :authorize!

  def index
    @tags = Tag.all.paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    @tag = Tag.new
    authorize!
  end

  def tag_params
    params[:tag].permit(:name) if params[:tag].present?
  end
  private :tag_params

  def edit; end

  def create
    @tag = Tag.new(tag_params)
    authorize!
    create_and_respond(object: @tag)
  end

  def set_tag
    @tag = Tag.find(params[:id])
    authorize!
  end
  private :set_tag

  def update
    update_and_respond(object: @tag, params: tag_params)
  end

  def destroy
    destroy_and_respond(object: @tag)
  end

  def to_s
    name
  end
end
