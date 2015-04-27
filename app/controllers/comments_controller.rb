class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy_by_id]

  # to disable authorization check: comment the line below back in
 # skip_after_action :verify_authorized

  def authorize!
    authorize(@comment || @comments)
  end
  private :authorize!

  # GET /comments
  # GET /comments.json
  def index
    #@comments = Comment.all
    #if admin, show all comments.
    #check whether user is the author of the passed file_id, if so, show all comments. otherwise, only show comments of auther and own comments
    file = CodeOcean::File.find(params[:file_id])
    #there might be no submission yet, so dont use find
    submission = Submission.find_by(id: file.context_id)
    if submission
      is_admin = false
      if current_user.respond_to? :external_id
        user_id = current_user.external_id
      else
        user_id = current_user.id
        is_admin = current_user.role == 'admin'
      end

      if(is_admin ||  user_id == submission.user_id)
        # fetch all comments for this file
        @comments = Comment.where(file_id: params[:file_id])
      else
        @comments = Comment.where(file_id: params[:file_id], user_id: user_id)
      end

      #@comments = Comment.where(file_id: params[:file_id])

      #add names to comments
      @comments.map{|comment| comment.username = Xikolo::UserClient.get(comment.user_id.to_s)[:display_name]}
    else
      @comments = Comment.where(file_id: -1) #we need an empty relation here
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
    @comment = Comment.new(comment_params.merge(user_type: current_user.class.name))

    respond_to do |format|
      if @comment.save
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
      if @comment.update(comment_params)
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
  def destroy_by_id
    @comment.destroy
    respond_to do |format|
      format.html { head :no_content, notice: 'Comment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def destroy
    @comments = Comment.where(file_id: params[:file_id], row: params[:row])
    @comments.delete_all
    respond_to do |format|
      #format.html { redirect_to comments_url, notice: 'Comments were successfully destroyed.' }
      format.html { head :no_content, notice: 'Comments were successfully destroyed.' }
      format.json { head :no_content }
    end
    authorize!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def comment_params
      #params.require(:comment).permit(:user_id, :file_id, :row, :column, :text)
      # fuer production mode, damit böse menschen keine falsche user_id uebergeben:
      params.require(:comment).permit(:file_id, :row, :column, :text).merge(user_id: current_user.id)
    end
end
