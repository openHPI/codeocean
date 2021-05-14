# frozen_string_literal: true

class PyUnitAndPyLintAdapter < TestingFrameworkAdapter
  def self.framework_name
    'PyUnit and PyLint'
  end

  def parse_output(output)
    if output[:file_role] == 'teacher_defined_linter'
      PyLintAdapter.new.parse_output(output)
    else
      PyUnitAdapter.new.parse_output(output)
    end
  end

  def translate_linter(result, locale)
    PyLintAdapter.translate_linter(result, locale)
  end
end
