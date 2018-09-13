class Testrun < ApplicationRecord
    belongs_to :file, class_name: 'CodeOcean::File'
    belongs_to :submission
end
