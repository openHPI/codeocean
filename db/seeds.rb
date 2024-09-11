# frozen_string_literal: true

# Meta seed file that required depending on the Rails env different files from
# db/seeds/ Please put the seed in the best matching file
#
#   * all: Objects are needed in every environment (production, development)
#   * production: Objects are only needed for deployment
#   * development: Only needed for local development

# Disable seeding if there are already internal users in the database
return if InternalUser.any?

def find_factories_by_class(klass)
  FactoryBot.factories.select do |factory|
    factory.instance_variable_get(:@class_name).to_s == klass.to_s || factory.instance_variable_get(:@name) == klass.model_name.singular.to_sym
  end
end

module ActiveRecord
  class Base
    %i[build create].each do |strategy|
      define_singleton_method(:"#{strategy}_factories") do |attributes = {}|
        find_factories_by_class(self).map(&:name).map do |factory_name|
          FactoryBot.send(strategy, factory_name, attributes)
        end
      end
    end
  end
end

['all', Rails.env].each do |seed|
  seed_file = Rails.root.join("db/seeds/#{seed}.rb")
  if seed_file.exist?
    puts "*** Loading \"#{seed}\" seed data" # rubocop:disable Rails/Output
    load seed_file
  else
    puts "*** Skipping \"#{seed}\" seed data: \"#{seed_file}\" not found" # rubocop:disable Rails/Output
  end
end
