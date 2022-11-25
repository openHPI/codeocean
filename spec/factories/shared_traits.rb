# frozen_string_literal: true

FactoryBot.define do
  %i[admin external_user teacher].each do |factory_name|
    trait :"created_by_#{factory_name}" do
      association :user, factory: factory_name
    end
  end

  trait :generated_email do
    email { "#{name.underscore.tr(' ', '.')}@example.org" }
  end

  trait :generated_user_name do
    name { Forgery(:name).full_name }
  end

  [ExternalUser, InternalUser].each do |klass|
    trait :"singleton_#{klass.name.underscore}" do
      initialize_with { klass.where(email:).first_or_create }
    end
  end

  trait :member_of_study_group do
    after(:create) do |user, evaluator|
      # Do not create a study group if already passed
      if user.study_groups.blank?
        study_group = create(:study_group)
        user.study_groups << study_group
      end

      user.study_group_memberships.update(role: 'teacher') if evaluator.teacher_in_study_group
      user.store_current_study_group_id(user.study_group_memberships.first.study_group_id)
    end
  end
end
