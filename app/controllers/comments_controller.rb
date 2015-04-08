class CommentsController < ApplicationController
  before_action :set_comment, only: [:show, :edit, :update, :destroy_by_id]

  # disable authorization check. TODO: turn this on later.
  skip_after_action :verify_authorized

  # GET /comments
  # GET /comments.json
  def index
    #@comments = Comment.all
    @comments = Comment.where(file_id: params[:file_id])
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
  end

  # GET /comments/new
  def new
    @comment = Comment.new
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(comment_params.merge(user_type: 'InternalUser'))

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @comment, notice: 'Comment was successfully created.' }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { render :new }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
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
