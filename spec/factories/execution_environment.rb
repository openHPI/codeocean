def create_programming_language_join(execution_environment, programming_language, default)
  execution_environment.programming_languages_joins << FactoryBot.build(:programming_languages_join,
                                                                default: default,
                                                                programming_language: programming_language,
                                                                execution_environment: execution_environment)
end

FactoryBot.define do
  factory :coffee_script, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-coffee:latest'
    association :file_type, factory: :dot_coffee
    help
    name 'CoffeeScript'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'coffee'
    singleton_execution_environment

    after(:build) do |coffee_script|
      create_programming_language_join(coffee_script, FactoryBot.create(:java_script_2_2), true)
    end
  end

  factory :html, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-html:latest'
    association :file_type, factory: :dot_html
    help
    name 'HTML5'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'touch'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'

    after(:build) do |html|
      create_programming_language_join(html, FactoryBot.create(:html_5), true)
    end
  end

  factory :java, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'openhpi/co_execenv_java:latest'
    association :file_type, factory: :dot_java
    help
    name 'Java 8'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'make run'
    singleton_execution_environment
    test_command 'make test CLASS_NAME="%{class_name}" FILENAME="%{filename}"'
    testing_framework 'JunitAdapter'

    after(:build) do |java|
      create_programming_language_join(java, FactoryBot.create(:java_8), true)
    end
  end

  factory :jruby, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-jruby:latest'
    association :file_type, factory: :dot_rb
    help
    name 'JRuby 1.7'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'jruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'

    after(:build) do |jruby|
      create_programming_language_join(jruby, FactoryBot.create(:ruby_2_2), false)
    end
  end

  factory :node_js, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-node:latest'
    association :file_type, factory: :dot_js
    help
    name 'Node.js'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'node %{filename}'
    singleton_execution_environment

    after(:build) do |node_js|
      create_programming_language_join(node_js, FactoryBot.create(:java_script_2_2), false)
    end
  end

  factory :python, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'openhpi/co_execenv_python:latest'
    association :file_type, factory: :dot_py
    help
    name 'Python 3.4'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'python3 %{filename}'
    singleton_execution_environment
    test_command 'python3 -m unittest --verbose %{module_name}'
    testing_framework 'PyUnitAdapter'

    after(:build) do |python|
      create_programming_language_join(python, FactoryBot.create(:python_3_0), true)
    end
  end

  factory :ruby, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-ruby:latest'
    association :file_type, factory: :dot_rb
    help
    name 'Ruby 2.2'
    network_enabled false
    permitted_execution_time 10.seconds
    pool_size 0
    run_command 'ruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'
    after(:build) do |ruby|
      create_programming_language_join(ruby, FactoryBot.create(:ruby_2_2), true)
    end
  end

  factory :sinatra, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-sinatra:latest'
    association :file_type, factory: :dot_rb
    exposed_ports '4567'
    help
    name 'Sinatra'
    network_enabled true
    permitted_execution_time 15.minutes
    pool_size 0
    run_command 'ruby %{filename}'
    singleton_execution_environment
    test_command 'rspec %{filename} --format documentation'
    testing_framework 'RspecAdapter'

    after(:build) do |sinatra|
      create_programming_language_join(sinatra, FactoryBot.create(:ruby_2_2), false)
    end
  end

  factory :sqlite, class: ExecutionEnvironment do
    created_by_teacher
    default_memory_limit
    docker_image 'hklement/ubuntu-sqlite:latest'
    association :file_type, factory: :dot_sql
    help
    name 'SQLite'
    network_enabled false
    permitted_execution_time 1.minute
    pool_size 0
    run_command 'sqlite3 /database.db -init %{filename} -html'
    singleton_execution_environment
    test_command 'ruby %{filename}'
    testing_framework 'SqlResultSetComparatorAdapter'

    after(:build) do |sqlite|
      create_programming_language_join(sqlite, FactoryBot.create(:sqlite_3), true)
    end
  end

  trait :default_memory_limit do
    memory_limit DockerClient::DEFAULT_MEMORY_LIMIT
  end

  trait :help do
    help { Forgery(:lorem_ipsum).words(Forgery(:basic).number(at_least: 50, at_most: 100)) }
  end

  trait :singleton_execution_environment do
    initialize_with { ExecutionEnvironment.where(name: name).first_or_initialize }
  end
end
