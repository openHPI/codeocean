class ExerciseCollectionsController < ApplicationController
  include CommonBehavior

  before_action :set_exercise_collection, only: [:show, :edit, :update, :destroy]

  def index
    @exercise_collections = ExerciseCollection.all.paginate(:page => params[:page])
    authorize!
  end

  def show
  end

  def new
    @exercise_collection = ExerciseCollection.new
    authorize!
  end

  def create
    @exercise_collection = ExerciseCollection.new(exercise_collection_params)
    authorize!
    create_and_respond(object: @exercise_collection)
  end

  def destroy
    authorize!
    destroy_and_respond(object: @exercise_collection)
  end

  def edit
  end

  def update
    update_and_respond(object: @exercise_collection, params: exercise_collection_params)
  end

  private

  def set_exercise_collection
    @exercise_collection = ExerciseCollection.find(params[:id])
    authorize!
  end

  def authorize!
    authorize(@exercise_collection || @exercise_collections)
  end

  def exercise_collection_params
    params[:exercise_collection].permit(:name, :exercise_ids => [])
  end
end
