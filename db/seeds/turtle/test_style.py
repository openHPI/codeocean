from pylint import epylint as lint
import glob

pylint_opts = ['--rcfile=default.pylintrc']
exercise = glob.glob('main.py')[0]
lint.lint(exercise, options=pylint_opts)
exit()
