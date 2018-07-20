class ExerciseCollection < ActiveRecord::Base
  include TimeHelper

  has_many :exercise_collection_items
  alias_method :items, :exercise_collection_items
  has_many :exercises, through: :exercise_collection_items
  belongs_to :user, polymorphic: true

  def collection_statistics
    statistics = {}
    exercise_collection_items.each do |item|
      statistics[item.position] = {exercise_id: item.exercise.id, exercise_title: item.exercise.title, working_time: time_to_f(item.exercise.average_working_time)}
    end
    statistics
  end

  def average_working_time
    if exercises.empty?
      0
    else
      values = collection_statistics.values.reject { |o| o[:working_time].nil?}
      sum = values.reduce(0) {|sum, item| sum + item[:working_time]}
      sum / values.size
    end
  end

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

end
