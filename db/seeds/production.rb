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
  admin = FactoryBot.create(:admin, email:, name: 'Administrator', password: passwords.first, study_groups: StudyGroup.all)
else
  abort('Passwords do not match!')
end

# file types
FileType.create_factories user: admin

# execution environments
ExecutionEnvironment.skip_callback(:commit, :after, :sync_runner_environment)
ExecutionEnvironment.create_factories user: admin

# exercises
Exercise.create_factories user: admin

# The old images included in the seed data do not feature a dedicated `user` and therefore require a privileged execution.
ExecutionEnvironment.update_all privileged_execution: true # rubocop:disable Rails/SkipsModelValidations

say(<<~CONFIRMATION_MESSAGE)
  Production data has been seeded successfully.

  As part of this setup, a test email was sent to \
  '#{email}'. You can safely ignore this mail as your \
  account is already confirmed. However, if you \
  haven't received any email, you should check the \
  server's mail settings.

  Additionally, some execution environments have been \
  stored in the database. However, these haven't been yet \
  synchronized with a runner management. Please take care \
  to configure a runner management according to the \
  documentation and synchronize environments through the \
  user interface. To do so, open `/execution_environments` \
  and click on the "Synchronize all" button.
CONFIRMATION_MESSAGE
