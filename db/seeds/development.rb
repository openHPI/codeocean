# frozen_string_literal: true

# consumers
FactoryBot.create(:consumer)
FactoryBot.create(:consumer, name: 'openSAP')
# The following consumer is preconfigured in Xikolo for local development
FactoryBot.create(:consumer, name: 'Xikolo Development', oauth_key: 'consumer', oauth_secret: 'secret')

# users
# Set default_url_options explicitly, required for rake task
Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
admin = FactoryBot.create(:admin)
teacher = FactoryBot.create(:teacher, email: 'teacher@example.org')
FactoryBot.create(:learner, email: 'learner@example.org')
external_user = FactoryBot.create(:external_user)

# file types
FileType.create_factories user: admin

# execution environments
ExecutionEnvironment.create_factories user: admin

# exercises
@exercises = find_factories_by_class(Exercise).map(&:name).index_with {|factory_name| FactoryBot.create(factory_name, user: teacher) }

# submissions
FactoryBot.create(:submission, exercise: @exercises[:fibonacci], user: external_user)
