class UserExerciseFeedbackController < ApplicationController
  include CommonBehavior

  def authorize!
    authorize(@uef)
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

  def uef_params
    params[:tag].permit(:feedback_text, :difficulty)
  end
  private :uef_params

  def new
    @uef = UserExerciseFeedback.new
    authorize!
  end

  def show
  end

  def update
    update_and_respond(object: @UserExerciseFeedback, params: uef_params)
  end

  def to_s
    name
  end
end