# frozen_string_literal: true

require 'highline/import'

# consumers
FactoryBot.create(:consumer)

# users
email = ask('Enter admin email: ')

passwords = ['password', 'password confirmation'].map do |attribute|
  ask("Enter admin #{attribute}: ") {|question| question.echo = false }
end

if passwords.uniq.length == 1
  admin = FactoryBot.create(:admin, email: email, name: 'Administrator', password: passwords.first)
else
  abort('Passwords do not match!')
end

# file types
FileType.create_factories user: admin

# execution environments
ExecutionEnvironment.create_factories user: admin

# exercises
Exercise.create_factories user: admin

say(<<~CONFIRMATION_MESSAGE)
  Production data has been seeded successfully. As part \
  of this setup, a test email was sent to '#{email}'. You \
  can safely ignore this mail as your account is already \
  confirmed. However, if you haven't received any email, \
  you should check the server's mail settings.
CONFIRMATION_MESSAGE
