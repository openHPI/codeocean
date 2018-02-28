class RequestForCommentsController < ApplicationController
  include SubmissionScoring
  before_action :set_request_for_comment, only: [:show, :edit, :update, :destroy, :mark_as_solved, :set_thank_you_note]

  skip_after_action :verify_authorized

  def authorize!
    authorize(@request_for_comments || @request_for_comment)
  end
  private :authorize!

  # GET /request_for_comments
  # GET /request_for_comments.json
  def index
    @search = RequestForComment
                  .last_per_user(2)
                  .with_last_activity
                  .search(params[:q])
    @request_for_comments = @search.result
                                .order('created_at DESC')
                                .paginate(page: params[:page], total_entries: @search.result.length)
    authorize!
  end

  # GET /my_request_for_comments
  def get_my_comment_requests
    @search = RequestForComment
                  .with_last_activity
                  .where(user_id: current_user.id)
                  .search(params[:q])
    @request_for_comments = @search.result
                                .order('created_at DESC')
                                .paginate(page: params[:page])
    render 'index'
  end

  # GET /my_rfc_activity
  def get_rfcs_with_my_comments
    @search = RequestForComment
                  .with_last_activity
                  .joins(:comments) # we don't need to outer join here, because we know the user has commented on these
                  .where(comments: {user_id: current_user.id})
                  .search(params[:q])
    @request_for_comments = @search.result
                                .order('last_comment DESC')
                                .paginate(page: params[:page])
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
    commenters.each {|commenter| UserMailer.send_thank_you_note(@request_for_comment, commenter).deliver_now}

    respond_to do |format|
      if @request_for_comment.save
        format.json { render :show, status: :ok, location: @request_for_comment }
      else
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /request_for_comments/1
  # GET /request_for_comments/1.json
  def show
    authorize!
  end

  # GET /request_for_comments/new
  def new
    @request_for_comment = RequestForComment.new
    authorize!
  end

  # GET /request_for_comments/1/edit
  def edit
  end

  # POST /request_for_comments
  # POST /request_for_comments.json
  def create
    @request_for_comment = RequestForComment.new(request_for_comment_params)
    respond_to do |format|
      if @request_for_comment.save
        # create thread here and execute tests. A run is triggered from the frontend and does not need to be handled here.
        Thread.new do
          score_submission(@request_for_comment.submission)
        end
        format.json { render :show, status: :created, location: @request_for_comment }
      else
        format.html { render :new }
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
    authorize!
  end

  def create_comment_exercise
    old = UserExerciseFeedback.find_by(exercise_id: params[:exercise_id], user_id: current_user.id, user_type: current_user.class.name)
    if old
      old.delete
    end
    uef = UserExerciseFeedback.new(comment_params)

    if uef.save
      render(json: {success: "true"})
    else
      render(json: {success: "false"})
    end
  end

  # DELETE /request_for_comments/1
  # DELETE /request_for_comments/1.json
  def destroy
    @request_for_comment.destroy
    respond_to do |format|
      format.html { redirect_to request_for_comments_url, notice: 'Request for comment was successfully destroyed.' }
      format.json { head :no_content }
    end
    authorize!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_request_for_comment
      @request_for_comment = RequestForComment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def request_for_comment_params
      # we are using the current_user.id here, since internal users are not able to create comments. The external_user.id is a primary key and does not require the consumer_id to be unique.
      params.require(:request_for_comment).permit(:exercise_id, :file_id, :question, :requested_at, :solved, :submission_id).merge(user_id: current_user.id, user_type: current_user.class.name)
    end

    def comment_params
      params.permit(:exercise_id, :feedback_text).merge(user_id: current_user.id, user_type: current_user.class.name)
    end

end
