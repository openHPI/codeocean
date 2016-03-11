class Testrun < ActiveRecord::Base
    belongs_to :file, class_name: 'CodeOcean::File'
    belongs_to :submission
end
