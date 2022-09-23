# frozen_string_literal: true

class AddStudyGroupAuthorization < ActiveRecord::Migration[6.1]
  def change
    add_column :external_users, :platform_admin, :boolean, default: false, null: false
    add_column :internal_users, :platform_admin, :boolean, default: false, null: false
    add_column :study_group_memberships, :role, :integer, limit: 1, null: false, default: 0, comment: 'Used as enum in Rails'
    add_reference :subscriptions, :study_group, index: true, null: true, foreign_key: true
    add_reference :authentication_tokens, :study_group, index: true, null: true, foreign_key: true
  end
end
