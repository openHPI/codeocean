class PyUnitAndPyLintAdapter < TestingFrameworkAdapter

  def self.framework_name
    'PyUnit and PyLint'
  end

  def parse_output(output)
    PyLintAdapter.new.parse_output(output)
  rescue NoMethodError
    # The regex for PyLint failed and did not return any matches
    PyUnitAdapter.new.parse_output(output)
  end
end
