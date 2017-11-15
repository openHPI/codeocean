require 'highline/import'

# consumers
FactoryBot.create(:consumer)

# users
email = ask('Enter admin email: ')

passwords = ['password', 'password confirmation'].map do |attribute|
  ask("Enter admin #{attribute}: ") { |question| question.echo = false }
end

if passwords.uniq.length == 1
  FactoryBot.create(:admin, email: email, name: 'Administrator', password: passwords.first)
else
  abort('Passwords do not match!')
end

# execution environments
ExecutionEnvironment.create_factories

# exercises
Exercise.create_factories

# file types
FileType.create_factories

# hints
Hint.create_factories

# change all resources' author
[ExecutionEnvironment, Exercise, FileType].each do |model|
  model.update_all(user_id: InternalUser.first.id)
end

# delete temporary users
InternalUser.where.not(id: InternalUser.first.id).delete_all
