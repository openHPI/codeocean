class Testrun < ActiveRecord::Base
    belongs_to :file
    belongs_to :submission
end
