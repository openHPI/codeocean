FactoryBot.define do
  [:admin, :external_user, :teacher].each do |factory_name|
    trait :"created_by_#{factory_name}" do
      association :user, factory: factory_name
    end
  end

  trait :generated_email do
    email { "#{name.underscore.gsub(' ', '.')}@example.org" }
  end

  trait :generated_user_name do
    name { Forgery(:name).full_name }
  end

  [ExternalUser, InternalUser].each do |klass|
    trait :"singleton_#{klass.name.underscore}" do
      initialize_with { klass.where(email: email).first_or_create }
    end
  end
end
