class ExerciseCollectionsController < ApplicationController
  include CommonBehavior

  before_action :set_exercise_collection, only: [:show, :edit, :update, :destroy, :statistics]

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

  def statistics
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
    sanitized_params = params[:exercise_collection].permit(:name, :use_anomaly_detection, :user_id, :user_type, :exercise_ids => []).merge(user_type: InternalUser.name)
    sanitized_params[:exercise_ids] = sanitized_params[:exercise_ids].reject {|v| v.nil? or v == ''}
    sanitized_params.tap {|p| p[:exercise_collection_items] = p[:exercise_ids].map.with_index {|_id, index| ExerciseCollectionItem.find_or_create_by(exercise_id: _id, exercise_collection_id: @exercise_collection.id, position: index)}; p.delete(:exercise_ids)}
  end
end
