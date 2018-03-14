class ExerciseCollectionsController < ApplicationController
  include CommonBehavior
  include TimeHelper

  before_action :set_exercise_collection, only: [:show, :edit, :update, :destroy, :statistics]

  def index
    @exercise_collections = ExerciseCollection.all.paginate(:page => params[:page])
    authorize!
  end

  def show
    @exercises = @exercise_collection.exercises.paginate(:page => params[:page])
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

  def statistics
    @working_times = {}
    @exercise_collection.exercises.each do |exercise|
      @working_times[exercise.id] = time_to_f exercise.average_working_time
    end
    @average = @working_times.values.reduce(:+) / @working_times.size
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
    params[:exercise_collection].permit(:name, :use_anomaly_detection, :user_id, :user_type, :exercise_ids => []).merge(user_type: InternalUser.name)
  end
end
