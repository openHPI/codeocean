class UserExerciseFeedbacksController < ApplicationController
  include CommonBehavior

  before_action :set_user_exercise_feedback, only: [:edit, :update]

  def comment_presets
    [[0,t('user_exercise_feedback.difficulty_easy')],
     [1,t('user_exercise_feedback.difficulty_some_what_easy')],
     [2,t('user_exercise_feedback.difficulty_ok')],
     [3,t('user_exercise_feedback.difficulty_some_what_difficult')],
     [4,t('user_exercise_feedback.difficult_too_difficult')]]
  end

  def time_presets
    [[0,t('user_exercise_feedback.estimated_time_less_5')],
     [1,t('user_exercise_feedback.estimated_time_5_to_10')],
     [2,t('user_exercise_feedback.estimated_time_10_to_20')],
     [3,t('user_exercise_feedback.estimated_time_20_to_30')],
     [4,t('user_exercise_feedback.estimated_time_more_30')]]
  end

  def authorize!
    authorize(@uef)
  end
  private :authorize!

  def create
    exercise = Exercise.find(uef_params[:exercise_id])
    if exercise
      @uef = UserExerciseFeedback.new(uef_params)
      if validate_inputs(uef_params)
        authorize!
        create_and_respond(object: @uef, path: proc{implement_exercise_path(exercise)})
      else
        flash[:danger] = t('shared.message_failure')
        redirect_to(:back, id: uef_params[:exercise_id])
      end
    end
  end

  def destroy
    destroy_and_respond(object: @tag)
  end

  def edit
    @texts = comment_presets.to_a
    @times = time_presets.to_a
    authorize!
  end

  def uef_params
    params[:user_exercise_feedback].permit(:feedback_text, :difficulty, :exercise_id, :user_estimated_worktime).merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :uef_params

  def new
    @texts = comment_presets.to_a
    @times = time_presets.to_a
    @uef = UserExerciseFeedback.new
    @exercise = Exercise.find(params[:user_exercise_feedback][:exercise_id])
    authorize!
  end

  def update
    authorize!
    if @exercise && validate_inputs(uef_params)
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
    @exercise = Exercise.find(params[:user_exercise_feedback][:exercise_id])
    @uef = UserExerciseFeedback.find_by(exercise_id: params[:user_exercise_feedback][:exercise_id], user: current_user)
  end

  def validate_inputs(uef_params)
    begin
      if uef_params[:difficulty].to_i < 0 || uef_params[:difficulty].to_i >= comment_presets.size
        return false
      elsif uef_params[:user_estimated_worktime].to_i < 0 || uef_params[:user_estimated_worktime].to_i >= time_presets.size
        return false
      else
        return true
      end
    rescue
      return false
    end
  end

end