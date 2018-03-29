FactoryBot.define do
  factory :python_3_0, class: ProgrammingLanguage do
    name 'Python'
    version '3.0'
  end

  factory :java_script_2_2, class: ProgrammingLanguage do
    name 'JavaScript'
    version '7'
  end

  factory :html_5, class: ProgrammingLanguage do
    name 'Html'
    version '5'
  end

  factory :java_8, class: ProgrammingLanguage do
    name 'Java'
    version '8'
  end

  factory :ruby_2_2, class: ProgrammingLanguage do
    name 'Ruby'
    version '2.2'
  end

  factory :python_3_6, class: ProgrammingLanguage do
    name 'Python'
    version '3.0'
  end

  factory :sqlite_3, class: ProgrammingLanguage do
    name 'SQLite'
    version '3'
  end
end