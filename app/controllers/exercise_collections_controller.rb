# frozen_string_literal: true

class ExerciseCollectionsController < ApplicationController
  include CommonBehavior

  before_action :set_exercise_collection, only: %i[show edit update destroy statistics]

  def index
    @exercise_collections = ExerciseCollection.all.paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    @exercise_collection = ExerciseCollection.new
    authorize!
  end

  def edit; end

  def create
    @exercise_collection = ExerciseCollection.new
    authorize!
    @exercise_collection.save
    update_and_respond(object: @exercise_collection, params: exercise_collection_params)
  end

  def update
    authorize!
    update_and_respond(object: @exercise_collection, params: exercise_collection_params)
  end

  def destroy
    authorize!
    destroy_and_respond(object: @exercise_collection)
  end

  def statistics; end

  private

  def set_exercise_collection
    @exercise_collection = ExerciseCollection.find(params[:id])
    authorize!
  end

  def authorize!
    authorize(@exercise_collection || @exercise_collections)
  end

  def exercise_collection_params
    sanitized_params = if params[:exercise_collection].present?
                         params[:exercise_collection].permit(:name,
                           :use_anomaly_detection, :user_id, :user_type, exercise_ids: []).merge(user_type: InternalUser.name)
                       else
                         {}
                       end
    sanitized_params[:exercise_ids] = sanitized_params[:exercise_ids].reject {|v| v.nil? or v == '' }
    sanitized_params.tap do |p|
      p[:exercise_collection_items] = p[:exercise_ids].map.with_index do |id, index|
        ExerciseCollectionItem.find_or_create_by(exercise_id: id, exercise_collection_id: @exercise_collection.id, position: index)
      end
      p.delete(:exercise_ids)
    end
  end
end
