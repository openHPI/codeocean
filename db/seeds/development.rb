# consumers
FactoryBot.create(:consumer)
FactoryBot.create(:consumer, name: 'openSAP')

# users
[:admin, :external_user, :teacher].each { |factory_name| FactoryBot.create(factory_name) }

# execution environments
ExecutionEnvironment.create_factories

# errors
Error.create_factories

# exercises
@exercises = find_factories_by_class(Exercise).map(&:name).map { |factory_name| [factory_name, FactoryBot.create(factory_name)] }.to_h

# file types
FileType.create_factories

# hints
Hint.create_factories

# submissions
FactoryBot.create(:submission, exercise: @exercises[:fibonacci])
