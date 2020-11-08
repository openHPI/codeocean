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

  def translate_linter(result)
    PyLintAdapter.translate_linter(result)
  end
end
