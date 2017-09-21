class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  # to disable authorization check: comment the line below back in
 # skip_after_action :verify_authorized

  def authorize!
    authorize(@comment || @comments)
  end
  private :authorize!

  # GET /comments
  # GET /comments.json
  def index
    file = CodeOcean::File.find(params[:file_id])
    #there might be no submission yet, so dont use find
    submission = Submission.find_by(id: file.context_id)
    if submission
      @comments = Comment.where(file_id: params[:file_id])
      @comments.map{|comment|
        comment.username = comment.user.displayname
        comment.date = comment.created_at.strftime('%d.%m.%Y %k:%M')
        comment.updated = (comment.created_at != comment.updated_at)
        comment.editable = comment.user == current_user
      }
    else
      @comments = []
    end
    authorize!
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
    authorize!
  end

  # GET /comments/new
  def new
    @comment = Comment.new
    authorize!
  end

  # GET /comments/1/edit
  def edit
    authorize!
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params_without_request_id)

    respond_to do |format|
      if @comment.save
        if comment_params[:request_id]
          request_for_comment = RequestForComment.find(comment_params[:request_id])
          send_mail_to_author @comment, request_for_comment
          send_mail_to_subscribers @comment, request_for_comment
        end

        format.html { redirect_to @comment, notice: 'Comment was successfully created.' }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { render :new }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
    authorize!
  end

  # PATCH/PUT /comments/1
  # PATCH/PUT /comments/1.json
  def update
    respond_to do |format|
      if @comment.update(comment_params_without_request_id)
        format.html { head :no_content, notice: 'Comment was successfully updated.' }
        format.json { render :show, status: :ok, location: @comment }
      else
        format.html { render :edit }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
    authorize!
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    authorize!
    @comment.destroy
    respond_to do |format|
      format.html { head :no_content, notice: 'Comment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params_without_request_id
    comment_params.except :request_id
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def comment_params
    #params.require(:comment).permit(:user_id, :file_id, :row, :column, :text)
    # fuer production mode, damit böse menschen keine falsche user_id uebergeben:
    params.require(:comment).permit(:file_id, :row, :column, :text, :request_id).merge(user_id: current_user.id, user_type: current_user.class.name)
  end

  def send_mail_to_author(comment, request_for_comment)
    if current_user != request_for_comment.user
      UserMailer.got_new_comment(comment, request_for_comment, current_user).deliver_now
    end
  end

  def send_mail_to_subscribers(comment, request_for_comment)
    request_for_comment.commenters.each do |commenter|
      already_sent_mail = false
      subscriptions = Subscription.where(
          :request_for_comment_id => request_for_comment.id,
          :user_id => commenter.id, :user_type => commenter.class.name,
          :deleted => false)
      subscriptions.each do |subscription|
        if (subscription.subscription_type == 'author' and current_user == request_for_comment.user) or subscription.subscription_type == 'all'
          unless subscription.user == current_user or already_sent_mail
            UserMailer.got_new_comment_for_subscription(comment, subscription, current_user).deliver_now
            already_sent_mail = true
          end
        end
      end
    end
  end
end
