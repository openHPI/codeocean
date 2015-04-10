class RequestForCommentsController < ApplicationController
  before_action :set_request_for_comment, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized

  def authorize!
    authorize(@request_for_comments || @request_for_comment)
  end
  private :authorize!

  # GET /request_for_comments
  # GET /request_for_comments.json
  def index
    # @request_for_comments = RequestForComment.all
    @request_for_comments = RequestForComment.all.order('created_at DESC').limit(50)
    authorize!
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

    file = CodeOcean::File.find(request_for_comment_params[:fileid])

    # get newest version of the file. this method is only called if there is at least one submission (prevented in frontend otherwise)
    # find newest submission for that exercise and user, use the file with the same filename for that.
    # this is necessary because the passed params are not up to date since the data attributes are not updated upon submission creation.

    # if we stat from the template, the context type is exercise. we find the newest submission based on the context_id and the current_user.id
      if(file.context_type =='Exercise')
        newest_submission = Submission.where(exercise_id: file.context_id, user_id: current_user.id).order('created_at DESC').first
      else
        # else we start from a submission. we find it it by the given context_id and retrieve the newest submission with the info of the known submission.
        submission = Submission.find(file.context_id)
        newest_submission = Submission.where(exercise_id: submission.exercise_id, user_id: submission.user_id).order('created_at DESC').first
      end
      newest_file = CodeOcean::File.where(context_id: newest_submission.id, name: file.name).first

    #finally, correct the fileid and create the request for comment
    request_for_comment_params[:fileid]=newest_file.id

    @request_for_comment = RequestForComment.new(request_for_comment_params)



    respond_to do |format|
      if @request_for_comment.save
        format.json { render :show, status: :created, location: @request_for_comment }
      else
        format.html { render :new }
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
    end
    authorize!
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
      params.require(:request_for_comment).permit(:requestorid, :exerciseid, :fileid, :requested_at)
    end
end
