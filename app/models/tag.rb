class Tag < ActiveRecord::Base

  has_many :exercise_tags
  has_many :exercises, through: :exercise_tags

  validates_uniqueness_of :name

  def destroy
    if (can_be_destroyed?)
      super
    end
  end

  def can_be_destroyed?
    !exercises.any?
  end

  def to_s
    name
  end

end