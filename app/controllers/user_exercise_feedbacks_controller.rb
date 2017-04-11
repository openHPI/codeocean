class UserExerciseFeedbacksController < ApplicationController
  include CommonBehavior

  before_action :set_user_exercise_feedback, only: [:edit, :update]

  def comment_presets
    [t('user_exercise_feedback.choose'),
     t('user_exercise_feedback.easy'),
     t('user_exercise_feedback.some_what_easy'),
     t('user_exercise_feedback.some_what_difficult'),
     t('user_exercise_feedback.difficult')]
  end

  def authorize!
    authorize(@uef)
  end
  private :authorize!

  def create
    if validate_feedback_text(uef_params[:difficulty])
      exercise = Exercise.find(uef_params[:exercise_id])
      if exercise
        @uef = UserExerciseFeedback.new(uef_params)
        authorize!
        create_and_respond(object: @uef, path: proc{implement_exercise_path(exercise)})
      end
    else
      flash[:danger] = t('shared.message_failure')
      redirect_to(:back, id: uef_params[:exercise_id])
    end
  end

  def destroy
    destroy_and_respond(object: @tag)
  end

  def edit
    @texts = comment_presets
    authorize!
  end

  def uef_params
    params[:user_exercise_feedback].permit(:feedback_text, :difficulty, :exercise_id).merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :uef_params

  def new
    @texts = comment_presets
    @uef = UserExerciseFeedback.new
    @exercise = Exercise.find(params[:user_exercise_feedback][:exercise_id])
    authorize!
  end

  def update
    authorize!
    if validate_feedback_text(uef_params[:difficulty]) && @exercise
      update_and_respond(object: @uef, params: uef_params, path: implement_exercise_path(@exercise))
    else
      flash[:danger] = t('shared.message_failure')
      redirect_to(:back, id: uef_params[:exercise_id])
    end
  end

  def to_s
    name
  end

  def set_user_exercise_feedback
    puts "params: #{params}"
    @exercise = Exercise.find(params[:user_exercise_feedback][:exercise_id])
    @uef = UserExerciseFeedback.find_by(exercise_id: params[:user_exercise_feedback][:exercise_id], user: current_user)
  end

  def validate_feedback_text(difficulty_text)
    return comment_presets.include? difficulty_text
  end
end