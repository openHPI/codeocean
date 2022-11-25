# frozen_string_literal: true

class UserExerciseFeedbacksController < ApplicationController
  include CommonBehavior

  before_action :set_user_exercise_feedback, only: %i[edit update destroy]
  before_action :set_presets, only: %i[new edit create update]

  def comment_presets
    [[0, t('user_exercise_feedback.difficulty_easy')],
     [1, t('user_exercise_feedback.difficulty_some_what_easy')],
     [2, t('user_exercise_feedback.difficulty_ok')],
     [3, t('user_exercise_feedback.difficulty_some_what_difficult')],
     [4, t('user_exercise_feedback.difficult_too_difficult')]]
  end

  def time_presets
    [[0, t('user_exercise_feedback.estimated_time_less_5')],
     [1, t('user_exercise_feedback.estimated_time_5_to_10')],
     [2, t('user_exercise_feedback.estimated_time_10_to_20')],
     [3, t('user_exercise_feedback.estimated_time_20_to_30')],
     [4, t('user_exercise_feedback.estimated_time_more_30')]]
  end

  def new
    exercise_id = if params[:user_exercise_feedback].nil?
                    params[:exercise_id]
                  else
                    params[:user_exercise_feedback][:exercise_id]
                  end
    @exercise = Exercise.find(exercise_id)
    @uef = UserExerciseFeedback.find_or_initialize_by(user: current_user, exercise: @exercise)
    authorize!
  end

  def edit
    authorize!
  end

  def create
    Sentry.set_extras(params: uef_params)

    @exercise = Exercise.find(uef_params[:exercise_id])
    rfc = RequestForComment.unsolved.where(exercise_id: @exercise.id, user_id: current_user.id).first
    submission = begin
      current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').first
    rescue StandardError
      nil
    end

    if @exercise
      @uef = UserExerciseFeedback.find_or_initialize_by(user: current_user, exercise: @exercise)
      @uef.update(uef_params)
      authorize!
      if validate_inputs(uef_params)
        path =
          if rfc && submission && submission.normalized_score.to_d == BigDecimal('1.0')
            request_for_comment_path(rfc)
          else
            implement_exercise_path(@exercise)
          end
        create_and_respond(object: @uef, path: proc { path })
      else
        flash.now[:danger] = t('shared.message_failure')
        redirect_back fallback_location: user_exercise_feedback_path(@uef)
      end
    end
  end

  def update
    submission = begin
      current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').final.first
    rescue StandardError
      nil
    end
    rfc = RequestForComment.unsolved.where(exercise_id: @exercise.id, user_id: current_user.id).first
    authorize!
    if @exercise && validate_inputs(uef_params)
      path =
        if rfc && submission && submission.normalized_score.to_d == BigDecimal('1.0')
          request_for_comment_path(rfc)
        else
          implement_exercise_path(@exercise)
        end
      update_and_respond(object: @uef, params: uef_params, path:)
    else
      flash.now[:danger] = t('shared.message_failure')
      redirect_back fallback_location: user_exercise_feedback_path(@uef)
    end
  end

  def destroy
    authorize!
    destroy_and_respond(object: @uef)
  end

  private

  def authorize!
    authorize(@uef || @uefs)
  end

  def to_s
    name
  end

  def set_user_exercise_feedback
    @uef = UserExerciseFeedback.find(params[:id])
    @exercise = @uef.exercise
  end

  def set_presets
    @texts = comment_presets.to_a
    @times = time_presets.to_a
  end

  def uef_params
    return if params[:user_exercise_feedback].blank?

    exercise_id = if params[:user_exercise_feedback].nil?
                    params[:exercise_id]
                  else
                    params[:user_exercise_feedback][:exercise_id]
                  end

    user_id = current_user.id
    user_type = current_user.class.name
    latest_submission = Submission
      .where(user_id:, user_type:, exercise_id:)
      .order(created_at: :desc).final.first

    authorize(latest_submission, :show?)

    params[:user_exercise_feedback]
      .permit(:feedback_text, :difficulty, :exercise_id, :user_estimated_worktime)
      .merge(user_id:,
        user_type:,
        submission: latest_submission,
        normalized_score: latest_submission&.normalized_score)
  end

  def validate_inputs(uef_params)
    if uef_params[:difficulty].to_i.negative? || uef_params[:difficulty].to_i >= comment_presets.size
      false
    else
      !(uef_params[:user_estimated_worktime].to_i.negative? || uef_params[:user_estimated_worktime].to_i >= time_presets.size)
    end
  rescue StandardError
    false
  end
end
