FactoryBot.define do
  factory :node_js_invalid_assignment, class: Hint do
    association :execution_environment, factory: :node_js
    english
    message 'There was an error with an assignment. Maybe you have to use the equality operator here.'
    name 'Invalid assignment'
    regular_expression 'Invalid left-hand side in assignment'
  end

  factory :node_js_reference_error, class: Hint do
    association :execution_environment, factory: :node_js
    english
    message "'$1' is not defined."
    name 'ReferenceError'
    regular_expression 'ReferenceError: (\w+) is not defined'
  end

  factory :node_js_syntax_error, class: Hint do
    association :execution_environment, factory: :node_js
    english
    message 'You seem to have made a typo.'
    name 'SyntaxError'
    regular_expression 'SyntaxError: Unexpected token (\w+)'
  end

  factory :ruby_load_error, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message "The file '$1' cannot be found."
    name 'LoadError'
    regular_expression 'cannot load such file -- (\w+) (LoadError)'
  end

  factory :ruby_name_error_constant, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message "The constant '$1' is not defined."
    name 'NameError (uninitialized constant)'
    regular_expression 'uninitialized constant (\w+) \(NameError\)'
  end

  factory :ruby_name_error_variable, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message "Your object '$2' of class '$3' does not know what '$1' is. Maybe you made a typo or still have to define '$1'."
    name 'NameError (undefined local variable or method)'
    regular_expression 'undefined local variable or method `(\w+)\' for (\w+):(\w+) \(NameError\)'
  end

  factory :ruby_no_method_error, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message "Your object '$2' of class '$3' does not understand the method '$1'. Maybe you made a typo or still have to implement that method."
    name 'NoMethodError'
    regular_expression 'undefined method `([\w\!\?=\[\]]+)\' for (\w+):(\w+) \(NoMethodError\)'
  end

  factory :ruby_syntax_error, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message 'You seem to have made a typo.'
    name 'SyntaxError'
    regular_expression 'syntax error'
  end

  factory :ruby_system_stack_error, class: Hint do
    association :execution_environment, factory: :ruby
    english
    message 'You seem to have built an infinite loop or recursion.'
    name 'SystemStackError'
    regular_expression 'stack level too deep \(SystemStackError\)'
  end

  factory :sqlite_no_such_column, class: Hint do
    association :execution_environment, factory: :sqlite
    english
    message "The column '$1' does not exist."
    name 'No Such Column'
    regular_expression 'no such column: (\w+)'
  end

  factory :sqlite_no_such_table, class: Hint do
    association :execution_environment, factory: :sqlite
    english
    message "The table '$1' does not exist."
    name 'No Such Table'
    regular_expression 'no such table: (\w+)'
  end

  factory :sqlite_syntax_error, class: Hint do
    association :execution_environment, factory: :sqlite
    english
    message "You seem to have made a typo near '$1'."
    name 'SyntaxError'
    regular_expression 'near "(\w+)": syntax error'
  end

  trait :english do
    locale 'en'
  end
end
