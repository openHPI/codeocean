class ExerciseCollection < ActiveRecord::Base

  has_and_belongs_to_many :exercises

  def to_s
    "#{I18n.t('activerecord.models.exercise_collection.one')}: #{name} (#{id})"
  end

end
