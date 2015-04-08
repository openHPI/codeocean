class RequestForCommentsController < ApplicationController
  before_action :set_request_for_comment, only: [:show, :edit, :update, :destroy]

  skip_after_action :verify_authorized


  # GET /request_for_comments
  # GET /request_for_comments.json
  def index
    @request_for_comments = RequestForComment.all
  end

  # GET /request_for_comments/1
  # GET /request_for_comments/1.json
  def show
  end

  # GET /request_for_comments/new
  def new
    @request_for_comment = RequestForComment.new
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
        format.json { render :show, status: :created, location: @request_for_comment }
      else
        format.html { render :new }
        format.json { render json: @request_for_comment.errors, status: :unprocessable_entity }
      end
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
