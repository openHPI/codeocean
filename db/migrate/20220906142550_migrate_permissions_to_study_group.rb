# frozen_string_literal: true

class MigratePermissionsToStudyGroup < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/SkipsModelValidations
  def up
    create_default_groups
    migrate_internal_users
    migrate_external_users
  end

  def create_default_groups
    Consumer.find_each do |consumer|
      StudyGroup.find_or_create_by!(consumer:, external_id: nil) do |new_group|
        new_group.name = "Default Study Group for #{consumer.name}"
      end
    end
  end

  def migrate_internal_users
    # Internal users don't necessarily have a study group yet, which is needed for the teacher role
    InternalUser.find_each do |user|
      user.update_columns(platform_admin: true) if user.role == 'admin'

      study_group = StudyGroup.find_by!(consumer: user.consumer, external_id: nil)

      # All platform admins will "just" be a teacher in the study group
      new_role = %w[admin teacher].include?(user.role) ? :teacher : :learner
      membership = StudyGroupMembership.find_or_create_by!(study_group:, user:)
      membership.update_columns(role: new_role)
    end
  end

  def migrate_external_users
    # All external users are (or will be) in a study group once launched through LTI
    # and therefore don't need a new StudyGroupMembership
    ExternalUser.where(role: 'admin').update(platform_admin: true)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
