class ExerciseCollection < ActiveRecord::Base
  include TimeHelper

  has_and_belongs_to_many :exercises
  belongs_to :user, polymorphic: true

  def average_working_time
    working_times = {}
    exercises.each do |exercise|
      working_times[exercise.id] = time_to_f exercise.average_working_time
    end
    working_times.values.reduce(:+) / working_times.size
  end

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

end
