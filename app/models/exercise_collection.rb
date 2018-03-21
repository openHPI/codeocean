class ExerciseCollection < ActiveRecord::Base
  include TimeHelper

  has_and_belongs_to_many :exercises
  belongs_to :user, polymorphic: true

  def exercise_working_times
    working_times = {}
    exercises.each do |exercise|
      working_times[exercise.id] = time_to_f exercise.average_working_time
    end
    working_times
  end

  def average_working_time
    exercise_working_times.values.reduce(:+) / exercises.size
  end

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

end
