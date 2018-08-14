class Event < ActiveRecord::Base
  belongs_to :user, polymorphic: true
  belongs_to :exercise
  belongs_to :file
end
