# frozen_string_literal: true

def find_factories_by_class(klass)
  FactoryBot.factories.select do |factory|
    factory.instance_variable_get(:@class_name).to_s == klass.to_s || factory.instance_variable_get(:@name) == klass.model_name.singular.to_sym
  end
end

module ActiveRecord
  class Base
    %i[build create].each do |strategy|
      define_singleton_method("#{strategy}_factories") do |attributes = {}|
        find_factories_by_class(self).map(&:name).map do |factory_name|
          FactoryBot.send(strategy, factory_name, attributes)
        end
      end
    end
  end
end

# delete all present records
Rails.application.eager_load!
(ApplicationRecord.descendants - [ActiveRecord::SchemaMigration, User]).each(&:delete_all)

# delete file uploads
FileUtils.rm_rf(Rails.public_path.join('uploads'))

# load environment-dependent seeds
load(Rails.root.join("db/seeds/#{Rails.env}.rb"))
