# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  # insights? is used in the flowr_controller.rb as we use it to authorize the user for a submission
  %i[download? download_file? run? score? show? statistics? stop? test? insights? finalize?].each do |action|
    define_method(action) { admin? || author? || author_in_programming_group? }
  end

  # download_submission_file? is used in the live_streams_controller.rb
  %i[render_file? download_submission_file?].each do |action|
    define_method(action) do
      # The AuthenticatedUrlHelper will check for more details, but we cannot determine a specific user
      everyone
    end
  end

  def index?
    admin?
  end

  def show_study_group?
    admin? || teacher_in_study_group?
  end
end
