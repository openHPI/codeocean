FactoryBot.define do
  factory :user_exercise_feedback, class: UserExerciseFeedback do
    created_by_external_user
    feedback_text 'Most suitable exercise ever'
  end

end
