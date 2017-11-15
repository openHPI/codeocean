require 'seeds_helper'

module CodeOcean
  FactoryBot.define do
    factory :file, class: CodeOcean::File do
      content ''
      association :context, factory: :submission
      association :file_type, factory: :dot_rb
      hidden false
      name { SecureRandom.hex }
      read_only false
      role 'main_file'
    end
  end
end
