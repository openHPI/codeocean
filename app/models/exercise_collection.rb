# frozen_string_literal: true

class ExerciseCollection < ApplicationRecord
  include TimeHelper

  has_many :exercise_collection_items, dependent: :delete_all
  alias items exercise_collection_items
  has_many :exercises, through: :exercise_collection_items, inverse_of: :exercise_collections
  belongs_to :user, polymorphic: true

  def collection_statistics
    statistics = {}
    exercise_collection_items.each do |item|
      statistics[item.position] =
        {exercise_id: item.exercise.id, exercise_title: item.exercise.title,
working_time: time_to_f(item.exercise.average_working_time)}
    end
    statistics
  end

  def average_working_time
    if exercises.empty?
      0
    else
      values = collection_statistics.values.reject {|o| o[:working_time].nil? }
      total_sum = values.reduce(0) {|sum, item| sum + item[:working_time] }
      total_sum / values.size
    end
  end

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id]
  end
end
