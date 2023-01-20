# frozen_string_literal: true

FactoryBot.define do
  factory :proxy_exercise, class: 'ProxyExercise' do
    created_by_teacher
    token { 'dummytoken' }
    title { 'Dummy' }
    algorithm { 'best_match' }
  end
end
