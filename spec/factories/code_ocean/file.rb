# frozen_string_literal: true

require 'seeds_helper'

module CodeOcean
  FactoryBot.define do
    factory :file, class: 'CodeOcean::File' do
      content { '' }
      context factory: :submission
      file_type factory: :dot_rb
      hidden { false }
      name { SecureRandom.hex }
      read_only { false }
      role { 'main_file' }

      trait(:image) do
        file_type factory: :dot_png
        name { 'poster' }
        after(:build) do |file|
          file.attachment.attach(
            io: Rails.root.join('db/seeds/audio_video/poster.png').open,
            filename: 'poster.png',
            content_type: 'image/png'
          )
        end
      end
    end

    factory :test_file, class: 'CodeOcean::File' do
      content { '' }
      context factory: :dummy
      file_type factory: :dot_rb
      hidden { true }
      name { SecureRandom.hex }
      read_only { true }
      role { 'teacher_defined_test' }
      feedback_message { 'feedback_message' }
      weight { 1 }
    end
  end
end
