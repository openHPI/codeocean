# frozen_string_literal: true

class SubmissionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  # insights? is used in the flowr_controller.rb as we use it to authorize the user for a submission
  # download_submission_file? is used in the live_streams_controller.rb
  %i[download? download_file? download_submission_file? run? score? show? statistics? stop? test?
     insights?].each do |action|
    define_method(action) { admin? || author? }
  end

  def render_file?
    everyone
  end

  def index?
    admin?
  end

  def show_study_group?
    admin? || teacher_in_study_group?
  end
end
