# frozen_string_literal: true

FactoryBot.define do
  factory :html, class: 'ExecutionEnvironment' do
    created_by_teacher
    default_memory_limit
    default_cpu_limit
    docker_image { 'openhpi/co_execenv_ruby:latest' }
    file_type { association :dot_html, user: }
    help
    name { 'HTML5' }
    network_enabled { false }
    privileged_execution { false }
    permitted_execution_time { 10.seconds }
    pool_size { 0 }
    run_command { 'touch' }
    singleton_execution_environment
    test_command { 'rspec %{filename} --format documentation' }
    testing_framework { 'RspecAdapter' }
  end

  factory :java, class: 'ExecutionEnvironment' do
    created_by_teacher
    memory_limit { 2 * ExecutionEnvironment::DEFAULT_MEMORY_LIMIT }
    default_cpu_limit
    docker_image { 'openhpi/co_execenv_java:8-antlr' }
    file_type { association :dot_java, user: }
    help
    name { 'Java 8' }
    network_enabled { false }
    privileged_execution { false }
    permitted_execution_time { 10.seconds }
    pool_size { 0 }
    run_command { 'make run' }
    singleton_execution_environment
    test_command { 'make test CLASS_NAME="%{class_name}" FILENAME="%{filename}"' }
    testing_framework { 'JunitAdapter' }
  end

  factory :node_js, class: 'ExecutionEnvironment' do
    created_by_teacher
    default_memory_limit
    default_cpu_limit
    docker_image { 'openhpi/co_execenv_node:latest' }
    file_type { association :dot_js, user: }
    help
    name { 'Node.js' }
    network_enabled { false }
    privileged_execution { false }
    permitted_execution_time { 10.seconds }
    pool_size { 0 }
    run_command { 'node %{filename}' }
    singleton_execution_environment
  end

  factory :python, class: 'ExecutionEnvironment' do
    created_by_teacher
    default_memory_limit
    default_cpu_limit
    docker_image { 'openhpi/co_execenv_python:3.4' }
    file_type { association :dot_py, user: }
    help
    name { 'Python 3.4' }
    network_enabled { false }
    privileged_execution { false }
    permitted_execution_time { 10.seconds }
    pool_size { 0 }
    run_command { 'python3 %{filename}' }
    singleton_execution_environment
    test_command { 'python3 -m unittest --verbose %{module_name}' }
    testing_framework { 'PyUnitAdapter' }
  end

  factory :ruby, class: 'ExecutionEnvironment' do
    created_by_teacher
    default_memory_limit
    default_cpu_limit
    docker_image { 'openhpi/co_execenv_ruby:latest' }
    file_type { association :dot_rb, user: }
    help
    name { 'Ruby 2.2' }
    network_enabled { false }
    privileged_execution { false }
    permitted_execution_time { 10.seconds }
    pool_size { 0 }
    run_command { 'ruby %{filename}' }
    singleton_execution_environment
    test_command { 'rspec %{filename} --format documentation' }
    testing_framework { 'RspecAdapter' }
  end

  trait :default_memory_limit do
    memory_limit { ExecutionEnvironment::DEFAULT_MEMORY_LIMIT }
  end

  trait :default_cpu_limit do
    cpu_limit { 20 }
  end

  trait :help do
    help { Forgery(:lorem_ipsum).words(Forgery(:basic).number(at_least: 50, at_most: 100)) }
  end

  trait :singleton_execution_environment do
    initialize_with { ExecutionEnvironment.where(name:).first_or_create }
  end
end
