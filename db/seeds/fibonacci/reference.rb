# frozen_string_literal: true

module Reference
  def fibonacci(number)
    number < 2 ? number : fibonacci(number - 1) + fibonacci(number - 2)
  end
end
