# frozen_string_literal: true

class PairProgrammingExerciseFeedbacksController < ApplicationController
  include CommonBehavior
  include RedirectBehavior

  before_action :set_presets, only: %i[new create]

  def comment_presets
    [[0, t('pair_programming_exercise_feedback.difficulty_easy')],
     [1, t('pair_programming_exercise_feedback.difficulty_some_what_easy')],
     [2, t('pair_programming_exercise_feedback.difficulty_ok')],
     [3, t('pair_programming_exercise_feedback.difficulty_some_what_difficult')],
     [4, t('pair_programming_exercise_feedback.difficult_too_difficult')]]
  end

  def time_presets
    [[0, t('pair_programming_exercise_feedback.estimated_time_less_5')],
     [1, t('pair_programming_exercise_feedback.estimated_time_5_to_10')],
     [2, t('pair_programming_exercise_feedback.estimated_time_10_to_20')],
     [3, t('pair_programming_exercise_feedback.estimated_time_20_to_30')],
     [4, t('pair_programming_exercise_feedback.estimated_time_more_30')]]
  end

  def reasons_presets
    [[0, t('pair_programming_exercise_feedback.reason_no_partner')],
     [1, t('pair_programming_exercise_feedback.reason_to_difficult_to_find_partner')],
     [2, t('pair_programming_exercise_feedback.reason_faster_alone')],
     [3, t('pair_programming_exercise_feedback.reason_not_working_with_strangers')],
     [4, t('pair_programming_exercise_feedback.reason_want_to_work_alone')],
     [5, t('pair_programming_exercise_feedback.reason_accidentally_alone')],
     [6, t('pair_programming_exercise_feedback.reason_other')]]
  end

  def new
    exercise_id = if params[:pair_programming_exercise_feedback].nil?
                    params[:exercise_id]
                  else
                    params[:pair_programming_exercise_feedback][:exercise_id]
                  end
    @exercise = Exercise.find(exercise_id)

    @submission = Submission.find(params[:pair_programming_exercise_feedback][:submission_id])
    authorize(@submission, :show?)

    @uef = PairProgrammingExerciseFeedback.new(user: current_user, exercise: @exercise, programming_group:, submission: @submission)
    authorize!
  end

  def create
    Sentry.set_extras(params: uef_params)

    @exercise = Exercise.find(uef_params[:exercise_id])

    if @exercise
      @uef = PairProgrammingExerciseFeedback.new(exercise: @exercise, programming_group:, study_group_id: current_user.current_study_group_id)
      @uef.update(uef_params)
      authorize!
      if validate_inputs(uef_params) && @uef.save
        redirect_after_submit
      else
        flash.now[:danger] = t('shared.message_failure')
        redirect_back fallback_location: pair_programming_exercise_feedback_path(@uef)
      end
    end
  end

  private

  def authorize!
    authorize(@uef || @uefs)
  end

  def set_presets
    @texts = comment_presets.to_a
    @times = time_presets.to_a
    @reasons = reasons_presets.to_a
  end

  def uef_params
    return if params[:pair_programming_exercise_feedback].blank?

    @submission = Submission.find(params[:pair_programming_exercise_feedback][:submission_id])

    authorize(@submission, :show?)

    params[:pair_programming_exercise_feedback]
      .permit(:difficulty, :user_estimated_worktime, :exercise_id)
      .merge(user: current_user,
        submission: @submission,
        normalized_score: @submission&.normalized_score)
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

  def programming_group
    current_contributor if current_contributor.programming_group?
  end
end
