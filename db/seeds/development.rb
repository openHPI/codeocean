# frozen_string_literal: true

require 'highline/import'

# consumers
FactoryBot.create(:consumer)
FactoryBot.create(:consumer, name: 'openSAP')
# The following consumer is preconfigured in Xikolo for local development
FactoryBot.create(:consumer, name: 'Xikolo Development', oauth_key: 'consumer', oauth_secret: 'secret')

# users
# Set default_url_options explicitly, required for rake task
Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
UserMailer.delivery_method = :test
admin = FactoryBot.create(:admin, study_groups: StudyGroup.all)
teacher = FactoryBot.create(:teacher, email: 'teacher@example.org', study_groups: StudyGroup.all)
FactoryBot.create(:learner, email: 'learner@example.org', study_groups: StudyGroup.all)
external_user = FactoryBot.create(:external_user, study_groups: StudyGroup.all)

# file types
FileType.create_factories user: admin

# execution environments
ExecutionEnvironment.skip_callback(:commit, :after, :sync_runner_environment)
ExecutionEnvironment.create_factories user: admin

# exercises
@exercises = find_factories_by_class(Exercise).map(&:name).index_with {|factory_name| FactoryBot.create(factory_name, user: teacher) }

# submissions
FactoryBot.create(:submission, exercise: @exercises[:fibonacci], user: external_user)

# The old images included in the seed data do not feature a dedicated `user` and therefore require a privileged execution.
ExecutionEnvironment.update_all privileged_execution: true # rubocop:disable Rails/SkipsModelValidations

say(<<~CONFIRMATION_MESSAGE)
  Development data has been seeded successfully.

  As part of this setup, some execution environments have been \
  stored in the database. However, these haven't been yet \
  synchronized with a runner management. Please take care \
  to configure a runner management according to the \
  documentation and synchronize environments through the \
  user interface. To do so, open `/execution_environments` \
  and click on the "Synchronize all" button.
CONFIRMATION_MESSAGE
