class ExerciseCollectionsController < ApplicationController

  before_action :set_exercise_collection, only: [:show]

  def index
    @exercise_collections = ExerciseCollection.all.paginate(:page => params[:page])
    authorize!
  end

  def show
  end


  private

  def set_exercise_collection
    @exercise_collection = ExerciseCollection.find(params[:id])
    authorize!
  end

  def authorize!
    authorize(@exercise_collection || @exercise_collections)
  end
end
