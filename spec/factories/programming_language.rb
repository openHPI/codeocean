FactoryBot.define do
  factory :python_3_0, class: ProgrammingLanguage do
    name 'Python'
    version '3.0'
    initialize_with_find_or_create
  end

  factory :java_script_2_2, class: ProgrammingLanguage do
    name 'JavaScript'
    version '7'
    initialize_with_find_or_create
  end

  factory :html_5, class: ProgrammingLanguage do
    name 'Html'
    version '5'
    initialize_with_find_or_create
  end

  factory :java_8, class: ProgrammingLanguage do
    name 'Java'
    version '8'
    initialize_with_find_or_create
  end

  factory :ruby_2_2, class: ProgrammingLanguage do
    name 'Ruby'
    version '2.2'
    initialize_with_find_or_create
  end

  factory :python_3_6, class: ProgrammingLanguage do
    name 'Python'
    version '3.0'
    initialize_with_find_or_create
  end

  factory :sqlite_3, class: ProgrammingLanguage do
    name 'SQLite'
    version '3'
    initialize_with_find_or_create
  end

  trait :initialize_with_find_or_create do
    initialize_with { ProgrammingLanguage.find_or_create_by(name: name, version: version) }
  end
end