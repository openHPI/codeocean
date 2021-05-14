# frozen_string_literal: true

require 'sqlite3'

REFERENCE_QUERY = File.new('reference.sql', 'r').read
STUDENT_QUERY = File.new('exercise.sql', 'r').read

database = SQLite3::Database.new('/database.db')

missing_tuples = database.execute(REFERENCE_QUERY) - database.execute(STUDENT_QUERY)
unexpected_tuples = database.execute(STUDENT_QUERY) - database.execute(REFERENCE_QUERY)

# rubocop:disable Rails/Output
puts("Missing tuples: #{missing_tuples}")
puts("Unexpected tuples: #{unexpected_tuples}")
# rubocop:enable Rails/Output
