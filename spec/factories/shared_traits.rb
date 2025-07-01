# frozen_string_literal: true

FactoryBot.define do
  %i[admin external_user teacher].each do |factory_name|
    trait :"created_by_#{factory_name}" do
      user factory: factory_name
    end
  end

  trait :generated_email do
    sequence(:email) {|n| "#{name.underscore.tr(' ', '.')}.#{n}@example.org" }
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
      if user.study_groups.blank? && user.is_a?(ExternalUser)
        # Do not create a study group if already passed
        study_group = create(:study_group, consumer: user.consumer)
        user.study_groups << study_group
      elsif user.is_a?(InternalUser)
        # Always add the user to the default study group
        default_study_group = user.consumer.study_groups.find_by(external_id: nil)
        StudyGroupMembership.find_or_create_by!(study_group: default_study_group, user:)
        # Reload the study groups to ensure the membership is reflected
        user.study_groups.reload
      end

      user.study_group_memberships.update(role: 'teacher') if evaluator.teacher_in_study_group
      user.store_current_study_group_id(user.study_group_memberships.first.study_group_id)
    end
  end
end
