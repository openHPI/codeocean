# frozen_string_literal: true

require 'seeds_helper'

def create_seed_file(exercise, path, file_attributes = {})
  file_extension = File.extname(path)
  file_type = FactoryBot.create(
    file_attributes[:file_type] || :"dot_#{file_extension.delete('.')}",
    user: exercise.user
  )
  name = File.basename(path).gsub(file_extension, '')
  file_attributes.merge!(file_type:, name:, path: path.split('/')[1..-2].join('/'), role: file_attributes[:role] || 'regular_file')
  if file_type.binary?
    file_attributes[:native_file] = File.open(SeedsHelper.seed_file_path(path), 'r')
  else
    file_attributes[:content] = SeedsHelper.read_seed_file(path)
  end
  exercise.add_file!(file_attributes)
end

FactoryBot.define do
  factory :audio_video, class: 'Exercise' do
    created_by_teacher
    description { "Try HTML's audio and video capabilities." }
    execution_environment { association :html, user: }
    instructions { 'Build a simple website including an HTML <audio> and <video> element. Link the following media files: chai.ogg, devstories.mp4.' }
    title { 'Audio & Video' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'audio_video/index.html', role: 'main_file')
      create_seed_file(exercise, 'audio_video/index.js')
      create_seed_file(exercise, 'audio_video/index.html_spec.rb', feedback_message: 'Your solution is not correct yet.', hidden: true, role: 'teacher_defined_test')
      create_seed_file(exercise, 'audio_video/chai.ogg', read_only: true)
      create_seed_file(exercise, 'audio_video/devstories.mp4', read_only: true)
      create_seed_file(exercise, 'audio_video/devstories.webm', read_only: true)
      create_seed_file(exercise, 'audio_video/poster.png', read_only: true)
    end
  end

  factory :dummy, class: 'Exercise' do
    created_by_teacher
    description { 'Dummy' }
    execution_environment { association :ruby, user: }
    instructions
    title { 'Dummy' }

    factory :dummy_with_user_feedbacks do
      # user_feedbacks_count is declared as a transient attribute and available in
      # attributes on the factory, as well as the callback via the evaluator
      transient do
        user_feedbacks_count { 5 }
      end

      # the after(:create) yields two values; the exercise instance itself and the
      # evaluator, which stores all values from the factory, including transient
      # attributes; `create_list`'s second argument is the number of records
      # to create and we make sure the user_exercise_feedback is associated properly to the exercise
      after(:create) do |exercise, evaluator|
        create_list(:user_exercise_feedback, evaluator.user_feedbacks_count, exercise:)
      end
    end
  end

  factory :even_odd, class: 'Exercise' do
    created_by_teacher
    description { 'Implement two methods even and odd which return whether a given number is even or odd, respectively.' }
    execution_environment { association :python, user: }
    instructions
    title { 'Even/Odd' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'even_odd/exercise.py', role: 'main_file')
      create_seed_file(exercise, 'even_odd/exercise_tests.py', feedback_message: 'Your solution is not correct yet.', hidden: true, role: 'teacher_defined_test')
      create_seed_file(exercise, 'even_odd/reference.py', hidden: true, role: 'reference_implementation')
    end
  end

  factory :fibonacci, class: 'Exercise' do
    created_by_teacher
    description { 'Implement a recursive function that calculates a requested Fibonacci number.' }
    execution_environment { association :ruby, user: }
    instructions
    title { 'Fibonacci Sequence' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'fibonacci/exercise.rb', role: 'main_file')
      create_seed_file(exercise, 'fibonacci/exercise_spec_1.rb', feedback_message: "The 'fibonacci' method is not defined correctly. Please take care that the method is called 'fibonacci', takes a single (integer) argument and returns an integer.", hidden: true, role: 'teacher_defined_test', weight: 1.5)
      create_seed_file(exercise, 'fibonacci/exercise_spec_2.rb', feedback_message: 'Your method does not work recursively. Please make sure that the method works in a divide-and-conquer fashion by calling itself for partial results.', hidden: true, role: 'teacher_defined_test', weight: 2)
      create_seed_file(exercise, 'fibonacci/exercise_spec_3.rb', feedback_message: 'Your method does not return the correct results for all tested input values. ', hidden: true, role: 'teacher_defined_test', weight: 3)
      create_seed_file(exercise, 'fibonacci/reference.rb', hidden: true, role: 'reference_implementation')
    end
  end

  factory :files, class: 'Exercise' do
    created_by_teacher
    description { 'Learn how to work with files.' }
    execution_environment { association :ruby, user: }
    instructions
    title { 'Working with Files' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'files/data.txt', read_only: true)
      create_seed_file(exercise, 'files/exercise.rb', role: 'main_file')
      create_seed_file(exercise, 'files/exercise_spec.rb', feedback_message: 'Your solution is not correct yet.', hidden: true, role: 'teacher_defined_test')
    end
  end

  factory :geolocation, class: 'Exercise' do
    created_by_teacher
    description { "Use the HTML5 Geolocation API to get the user's geographical position." }
    execution_environment { association :html, user: }
    instructions
    title { 'Geolocation' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'geolocation/index.html', role: 'main_file')
      create_seed_file(exercise, 'geolocation/index.js')
    end
  end

  factory :hello_world, class: 'Exercise' do
    created_by_teacher
    description { "Write a simple 'Hello World' application." }
    execution_environment { association :ruby, user: }
    instructions
    title { 'Hello World' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'hello_world/exercise.rb', role: 'main_file')
      create_seed_file(exercise, 'hello_world/exercise_spec.rb', feedback_message: 'Your solution is not correct yet.', hidden: true, role: 'teacher_defined_test')
    end
  end

  factory :math, class: 'Exercise' do
    created_by_teacher
    description { 'Implement a recursive math library.' }
    execution_environment { association :java, user: }
    instructions
    title { 'Math' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'math/Makefile', file_type: :makefile, hidden: true, role: 'regular_file')
      create_seed_file(exercise, 'math/org/example/RecursiveMath.java', role: 'main_file')
      create_seed_file(exercise, 'math/org/example/RecursiveMathTest1.java', feedback_message: "The 'power' method is not defined correctly. Please take care that the method is called 'power', takes two arguments and returns a double.", hidden: true, role: 'teacher_defined_test')
      create_seed_file(exercise, 'math/org/example/RecursiveMathTest2.java', feedback_message: 'Your solution yields wrong results.', hidden: true, role: 'teacher_defined_test')
    end
  end

  factory :primes, class: 'Exercise' do
    created_by_teacher
    description { 'Write a function that prints the first n prime numbers.' }
    execution_environment { association :node_js, user: }
    instructions
    title { 'Primes' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'primes/exercise.js', role: 'main_file')
    end
  end

  factory :tdd, class: 'Exercise' do
    created_by_teacher
    description { 'Learn to appreciate test-driven development.' }
    execution_environment { association :ruby, user: }
    instructions { SeedsHelper.read_seed_file('tdd/instructions.md') }
    title { 'Test-driven Development' }

    after(:create) do |exercise|
      create_seed_file(exercise, 'tdd/exercise.rb', role: 'main_file')
      create_seed_file(exercise, 'tdd/exercise_spec.rb', role: 'user_defined_test')
    end
  end

  trait :instructions do
    instructions { Forgery(:lorem_ipsum).words(Forgery(:basic).number(at_least: 50, at_most: 100)) }
  end
end
