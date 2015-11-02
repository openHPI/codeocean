# consumers
FactoryGirl.create(:consumer)
FactoryGirl.create(:consumer, name: 'openSAP')

# users
[:admin, :external_user, :teacher].each { |factory_name| FactoryGirl.create(factory_name) }

# execution environments

# CoreOS Adjustment: 
# We don't need to create the execution environments here anymore
# ExecutionEnvironment.create_factories

# errors
Error.create_factories

# exercises
@exercises = find_factories_by_class(Exercise).map(&:name).map { |factory_name| [factory_name, FactoryGirl.create(factory_name)] }.to_h

# file types
FileType.create_factories

# hints
Hint.create_factories

# submissions
FactoryGirl.create(:submission, exercise: @exercises[:fibonacci])

# teams
FactoryGirl.create(:team, internal_users: InternalUser.limit(10))
