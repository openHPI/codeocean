# frozen_string_literal: true

class DropErrors < ActiveRecord::Migration[5.2]
  # define old CodeOcean::Error module so that the migration works
  module CodeOcean
    class Error < ApplicationRecord
      belongs_to :execution_environment

      scope :for_execution_environment, ->(execution_environment) { where(execution_environment_id: execution_environment.id) }
      scope :grouped_by_message, -> { select('MAX(created_at) AS created_at, MAX(id) AS id, message, COUNT(id) AS count').group(:message).order('count DESC') }

      validates :message, presence: true

      def self.nested_resource?
        true
      end

      delegate :to_s, to: :id
    end
  end

  def change
    Rails.logger.info 'Migrating CodeOcean::Errors to StructuredErrors using RegEx. This might take a (long) while but will return.'
    submissions_controller = SubmissionsController.new

    # Iterate only over those Errors containing a message and submission_id
    CodeOcean::Error.where.not(message: [nil, '']).where.not(submission_id: [nil, '']).each do |error|
      raw_output = error.message
      submission = Submission.find_by(id: error.submission_id)

      # Validate that we have everything we need: the output, the submission and the execution environment
      next if submission.blank? || submission.exercise.execution_environment.blank?

      submissions_controller.instance_variable_set(:@raw_output, raw_output)
      submissions_controller.instance_variable_set(:@submission, submission)
      submissions_controller.send(:extract_errors)
    end

    drop_table :errors
  end
end
