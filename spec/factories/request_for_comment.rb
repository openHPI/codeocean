FactoryBot.define do
  factory :rfc, class: RequestForComment do
    association :user, factory: :external_user
    association :submission
    association :exercise, factory: :dummy
    association :file
    sequence :question do |n|
      "test question #{n}"
    end
  end
end
