FactoryGirl.define do
  factory :coffee_script, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-coffee:latest'
    help
    name 'CoffeeScript'
    permitted_execution_time 10.seconds
    run_command 'coffee'
    singleton_execution_environment
  end

  factory :html, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-html:latest'
    help
    name 'HTML5'
    permitted_execution_time 10.seconds
    run_command 'touch'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'
  end

  factory :java, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-java:latest'
    help
    name 'Java 8'
    permitted_execution_time 10.seconds
    run_command 'make run'
    singleton_execution_environment
    test_command 'make test CLASS_NAME="%{class_name}" FILENAME="%{filename}"'
    testing_framework 'JunitAdapter'
  end

  factory :jruby, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-jruby:latest'
    help
    name 'JRuby 1.7'
    permitted_execution_time 10.seconds
    run_command 'ruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'
  end

  factory :node_js, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-node:latest'
    help
    name 'Node.js'
    permitted_execution_time 10.seconds
    run_command 'node %{filename}'
    singleton_execution_environment
  end

  factory :python, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-python:latest'
    help
    name 'Python 2.7'
    permitted_execution_time 10.seconds
    run_command 'python %{filename}'
    singleton_execution_environment
    test_command 'python -m unittest --verbose %{module_name}'
    testing_framework 'PyUnitAdapter'
  end

  factory :ruby, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-ruby:latest'
    help
    name 'Ruby 2.1'
    permitted_execution_time 10.seconds
    run_command 'ruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'
  end

  factory :sinatra, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-sinatra:latest'
    exposed_ports '4567'
    help
    name 'Sinatra'
    permitted_execution_time 15.minutes
    run_command 'ruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'
  end

  factory :sqlite, class: ExecutionEnvironment do
    created_by_teacher
    docker_image 'hklement/ubuntu-sqlite:latest'
    help
    name 'SQLite'
    permitted_execution_time 1.minute
    run_command 'sqlite3 /database.db -init %{filename} -html'
    singleton_execution_environment
    test_command 'ruby %{filename}'
    testing_framework 'SqlResultSetComparatorAdapter'
  end

  trait :help do
    help { Forgery(:lorem_ipsum).words(Forgery(:basic).number(at_least: 50, at_most: 100)) }
  end

  trait :singleton_execution_environment do
    initialize_with { ExecutionEnvironment.where(name: name).first_or_create }
  end
end
