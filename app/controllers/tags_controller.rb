class TagsController < ApplicationController
  include CommonBehavior

  before_action :set_tag, only: MEMBER_ACTIONS

  def authorize!
    authorize(@tag || @tags)
  end
  private :authorize!

  def create
    @tag = Tag.new(tag_params)
    authorize!
    create_and_respond(object: @tag)
  end

  def destroy
    destroy_and_respond(object: @tag)
  end

  def edit
  end

  def tag_params
    params[:tag].permit(:name)
  end
  private :tag_params

  def index
    @tags = Tag.all.paginate(page: params[:page])
    authorize!
  end

  def new
    @tag = Tag.new
    authorize!
  end

  def set_tag
    @tag = Tag.find(params[:id])
    authorize!
  end
  private :set_tag

  def show
  end

  def update
    update_and_respond(object: @tag, params: tag_params)
  end

  def to_s
    name
  end
end
