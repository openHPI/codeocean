FactoryBot.define do
  factory :programming_languages_join, class: ProgrammingLanguagesJoin do
    default true
    association :programming_language, factory: :java_8
    association :execution_environment, factory: :java
  end
end