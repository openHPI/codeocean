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
    #check whether user is the author of the passed file_id, if so, show all comments. otherwise, only show comments of the file-author and own comments
    file = CodeOcean::File.find(params[:file_id])
    #there might be no submission yet, so dont use find
    submission = Submission.find_by(id: file.context_id)
    if submission
      is_admin = false
      user_id = current_user.id

      # if we have an internal user, check whether he is an admin
      if not current_user.respond_to? :external_id
        is_admin = current_user.role == 'admin'
      end

      if(is_admin ||  user_id == submission.user_id)
        # fetch all comments for this file
        @comments = Comment.where(file_id: params[:file_id])
      else
        # fetch comments of the current user
        #@comments = Comment.where(file_id: params[:file_id], user_id: user_id)
        # fetch comments of file-author and the current user
        @comments = Comment.where(file_id: params[:file_id], user_id: [user_id, submission.user_id])
      end

      #add names to comments
      # if the user is internal, set the name

      @comments.map{|comment|
        if(comment.user_type == 'InternalUser')
          comment.username = InternalUser.find(comment.user_id).name
        elsif(comment.user_type == 'ExternalUser')
          comment.username = ExternalUser.find(comment.user_id).name
          # alternative: # if the user is external, fetch the displayname from xikolo
          # Xikolo::UserClient.get(comment.user_id.to_s)[:display_name]
        end
      }
    else
      @comments = Comment.all.limit(0) #we need an empty relation here
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
    @comment = Comment.new(comment_params)

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
      params.require(:comment).permit(:file_id, :row, :column, :text).merge(user_id: current_user.id, user_type: current_user.class.name)
    end
end
