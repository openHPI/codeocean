# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    file { create(:rfc).file }
    user factory: :learner
    row { 1 }
    text { "comment on file #{file.id} on #{row}" }
  end
end
