# frozen_string_literal: true

class RequestForCommentsController < ApplicationController
  include CommonBehavior
  before_action :require_user!
  before_action :set_request_for_comment, only: %i[show mark_as_solved set_thank_you_note clear_question]
  before_action :set_study_group_grouping,
    only: %i[index my_comment_requests rfcs_with_my_comments rfcs_for_exercise]

  def authorize!
    authorize(@request_for_comments || @request_for_comment)
  end
  private :authorize!

  # GET /request_for_comments
  # GET /request_for_comments.json
  def index
    @search = policy_scope(RequestForComment)
      .last_per_user(2)
      .joins(:exercise)
      .where(exercises: {unpublished: false})
      .order(created_at: :desc) # Order for the LIMIT part of the query
      .ransack(params[:q])

    # This total is used later to calculate the total number of entries
    request_for_comments = @search.result
      # All conditions are included in the query, so get the number of requested records
      .paginate(page: params[:page], per_page: per_page_param)

    @request_for_comments = RequestForComment.where(id: request_for_comments)
      .with_last_activity # expensive query, so we only do it for the current page
      .includes(submission: %i[study_group exercise])
      .includes(:file, :comments, :user)
      .order(created_at: :desc) # Order for the view
      # We need to manually enable the pagination links.
      .extending(WillPaginate::ActiveRecord::RelationMethods)
    @request_for_comments.current_page = WillPaginate::PageNumber(params[:page] || 1)
    @request_for_comments.limit_value = per_page_param
    @request_for_comments.total_entries = @search.result.length

    authorize!
  end

  # GET /my_request_for_comments
  def my_comment_requests
    @search = policy_scope(RequestForComment)
      .where(user: current_user)
      .order(created_at: :desc) # Order for the LIMIT part of the query
      .ransack(params[:q])

    # This total is used later to calculate the total number of entries
    request_for_comments = @search.result
      # All conditions are included in the query, so get the number of requested records
      .paginate(page: params[:page], per_page: per_page_param)

    @request_for_comments = RequestForComment.where(id: request_for_comments)
      .with_last_activity
      .includes(submission: %i[study_group exercise])
      .includes(:file, :comments, :user)
      .order(created_at: :desc) # Order for the view
      # We need to manually enable the pagination links.
      .extending(WillPaginate::ActiveRecord::RelationMethods)
    @request_for_comments.current_page = WillPaginate::PageNumber(params[:page] || 1)
    @request_for_comments.limit_value = per_page_param
    @request_for_comments.total_entries = @search.result.length

    authorize!
    render 'index'
  end

  # GET /my_rfc_activity
  def rfcs_with_my_comments
    # As we order by `last_comment`, we need to include `with_last_activity` in the original query.
    # Therefore, the optimization chosen above doesn't work here.
    @search = policy_scope(RequestForComment)
      .with_last_activity
      .joins(:comments) # we don't need to outer join here, because we know the user has commented on these
      .where(comments: {user: current_user})
      .ransack(params[:q])
    @request_for_comments = @search.result
      .includes(submission: [:study_group, :exercise, {files: %i[comments]}])
      .includes(:user)
      .order(last_comment: :desc)
      .paginate(page: params[:page], per_page: per_page_param)
    authorize!
    render 'index'
  end

  # GET /exercises/:id/request_for_comments
  def rfcs_for_exercise
    exercise = Exercise.find(params[:exercise_id])
    @search = policy_scope(RequestForComment)
      .with_last_activity
      .where(exercise_id: exercise.id)
      .ransack(params[:q])
    @request_for_comments = @search.result
      .joins(:exercise)
      .order(last_comment: :desc)
      .paginate(page: params[:page], per_page: per_page_param)
    # let the exercise decide, whether its rfcs should be visible
    authorize(exercise)
    render 'index'
  end

  # GET /request_for_comments/1/mark_as_solved
  def mark_as_solved
    authorize!
    @request_for_comment.solved = true
    respond_to do |format|
      if @request_for_comment.save
        format.json { render :show, status: :ok, location: @request_for_comment }
      else
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /request_for_comments/1/set_thank_you_note
  def set_thank_you_note
    authorize!
    @request_for_comment.thank_you_note = params[:note]

    commenters = @request_for_comment.commenters
    commenters.each {|commenter| UserMailer.send_thank_you_note(@request_for_comment, commenter).deliver_now }

    respond_to do |format|
      if @request_for_comment.save
        format.json { render :show, status: :ok, location: @request_for_comment }
      else
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /request_for_comments/1/clear_question
  def clear_question
    authorize!
    update_and_respond(object: @request_for_comment, params: {question: nil})
  end

  # GET /request_for_comments/1
  # GET /request_for_comments/1.json
  def show
    authorize!
  end

  # POST /request_for_comments.json
  def create
    # Consider all requests as JSON
    request.format = 'json'
    raise Pundit::NotAuthorizedError if @embed_options[:disable_rfc]

    @request_for_comment = RequestForComment.new(request_for_comment_params)

    respond_to do |format|
      if @request_for_comment.save
        # execute the tests here and wait until they finished.
        # As the same runner is used for the score and test run, no parallelization is possible
        # A run is triggered from the frontend and does not need to be handled here.
        @request_for_comment.submission.calculate_score
        format.json { render :show, status: :created, location: @request_for_comment }
      else
        format.html { render :new }
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
    authorize!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_request_for_comment
    @request_for_comment = RequestForComment.find(params[:id])
  end

  def request_for_comment_params
    # The study_group_id might not be present in the session (e.g. for internal users), resulting in session[:study_group_id] = nil which is intended.
    params.require(:request_for_comment).permit(:exercise_id, :file_id, :question, :requested_at, :solved, :submission_id).merge(
      user_id: current_user.id, user_type: current_user.class.name
    )
  end

  # The index page requires the grouping of the study groups
  # The study groups are grouped by the current study group and other study groups of the user
  def set_study_group_grouping
    current_study_group = StudyGroup.find_by(id: session[:study_group_id])
    my_study_groups = case current_user.consumer.rfc_visibility
                        when 'all' then current_user.study_groups.order(name: :desc)
                        when 'consumer' then current_user.study_groups.where(consumer: current_user.consumer).order(name: :desc)
                        when 'study_group' then current_study_group.present? ? Array(current_study_group) : []
                        else raise "Unknown RfC Visibility #{current_user.consumer.rfc_visibility}"
                      end

    @study_groups_grouping = [[t('request_for_comments.index.study_groups.current'), Array(current_study_group)],
                              [t('request_for_comments.index.study_groups.my'), my_study_groups.reject {|group| group == current_study_group }]]
  end
end
