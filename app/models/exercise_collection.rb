class ExerciseCollection < ActiveRecord::Base
  include TimeHelper

  has_many :exercise_collection_items
  alias_method :items, :exercise_collection_items
  has_many :exercises, through: :exercise_collection_items
  belongs_to :user, polymorphic: true

  def exercise_working_times
    working_times = {}
    exercises.each do |exercise|
      working_times[exercise.id] = time_to_f exercise.average_working_time
    end
    working_times
  end

  def average_working_time
    if exercises.empty?
      0
    else
      values = exercise_working_times.values.reject { |v| v.nil?}
      values.reduce(:+) / exercises.size
    end
  end

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

end
