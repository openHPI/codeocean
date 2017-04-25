class Search < ActiveRecord::Base
  belongs_to :user, polymorphic: true
  belongs_to :exercise
end