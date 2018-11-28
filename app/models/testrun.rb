class Testrun < ApplicationRecord
    belongs_to :file, class_name: 'CodeOcean::File', optional: true
    belongs_to :submission
end
