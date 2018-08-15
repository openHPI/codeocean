class Event < ActiveRecord::Base
  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :file

  validates :category, presence: true
  validates :data, presence: true
end
