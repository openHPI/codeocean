class SearchesController < ApplicationController
  include CommonBehavior

  def authorize!
    authorize(@search || @searchs)
  end
  private :authorize!


  def create
    @search = Search.new(search_params)
    @search.user = current_user
    authorize!

    respond_to do |format|
      if @search.save
        path = implement_exercise_path(@search.exercise)
        respond_with_valid_object(format, path: path, status: :created)
      end
    end
  end

  def search_params
    params[:search].permit(:search, :exercise_id)
  end
  private :search_params

  def index
    @search = policy_scope(ProxyExercise).search(params[:q])
    @searches = @search.result.order(:title).paginate(page: params[:page])
    authorize!
  end

end