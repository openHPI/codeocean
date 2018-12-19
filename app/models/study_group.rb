# frozen_string_literal: true

class StudyGroup < ApplicationRecord
  has_many :study_group_memberships
  # Use `ExternalUser` as `source_type` for now.
  # Using `User` will lead ActiveRecord to access the inexistent table `users`.
  # Issue created: https://github.com/rails/rails/issues/34531
  has_many :users, through: :study_group_memberships, source_type: 'ExternalUser'
  has_many :submissions
  belongs_to :consumer
end
