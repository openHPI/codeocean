# frozen_string_literal: true

class CommunitySolutionsController < ApplicationController
  include CommonBehavior
  include RedirectBehavior
  include SubmissionParameters

  before_action :require_user!
  before_action :set_community_solution, only: %i[edit update]
  before_action :set_community_solution_lock, only: %i[edit]
  before_action :set_exercise_and_submission, only: %i[edit update]

  # GET /community_solutions
  def index
    @community_solutions = CommunitySolution.all.paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  # GET /community_solutions/1/edit
  def edit
    authorize!

    # Be safe. Only allow access to this page if user has valid lock
    redirect_after_submit unless @community_solution_lock.present? && @community_solution_lock.active? && @community_solution_lock.user == current_user && @community_solution_lock.community_solution == @community_solution
    # We don't want to perform any of the following steps if we rendered already (e.g. due to a redirect)
    return if performed?

    last_contribution = CommunitySolutionContribution.where(community_solution: @community_solution, timely_contribution: true, autosave: false, proposed_changes: true).order(created_at: :asc).last
    @files = []
    if last_contribution.blank?
      last_contribution = @community_solution.exercise
      new_readme_file = {content: '', file_type: FileType.find_by(file_extension: '.txt'), hidden: false, read_only: false, name: 'ReadMe', role: 'regular_file', context: @community_solution}
      # If the first user did not save, the ReadMe file already exists
      @files << CodeOcean::File.find_or_create_by!(new_readme_file)
    end
    all_visible_files = last_contribution.files.select(&:visible)
    # Add the ReadMe file first
    @files += all_visible_files.select {|f| CodeOcean::File.find_by(id: f.file_id)&.context_type == 'CommunitySolution' }
    # Then, add all remaining files and sort them by name with extension
    @files += (all_visible_files - @files).sort_by(&:filepath)

    # Own Submission as a reference
    @own_files = @submission.collect_files.select(&:visible).sort_by(&:filepath)
    # Remove the file_id from the second graph. Otherwise, the comparison and file-tree selection does not work as expected
    @own_files.map do |file|
      file.file_id = nil
      file.read_only = true
    end
  end

  # PATCH/PUT /community_solutions/1
  def update
    authorize!
    contribution_params = submission_params
    cause = contribution_params.delete(:cause)
    contribution_params[:proposed_changes] = cause == 'change-community-solution'
    contribution_params[:autosave] = cause == 'autosave-community-solution'
    contribution_params.delete(:exercise_id)
    contribution_params[:community_solution] = @community_solution

    # Acquire lock here! This is expensive but required for synchronization
    @community_solution_lock = ActiveRecord::Base.transaction do
      ApplicationRecord.connection.exec_query("LOCK #{CommunitySolutionLock.table_name} IN ACCESS EXCLUSIVE MODE")

      lock = CommunitySolutionLock.where(user: current_user, community_solution: @community_solution).order(locked_until: :asc).last

      if lock.active?
        contribution_params[:timely_contribution] = true
        # Update lock: Either expand the time (autosave) or return it (change / accept)
        new_lock_time = contribution_params[:autosave] ? 5.minutes.from_now : Time.zone.now
        lock.update!(locked_until: new_lock_time)
      else
        contribution_params[:timely_contribution] = false
      end
      # This is returned
      lock
    end

    contribution_params[:community_solution_lock] = @community_solution_lock
    contribution_params[:working_time] = @community_solution_lock.working_time
    CommunitySolutionContribution.create(contribution_params)

    redirect_after_submit
  end

  private

  def authorize!
    authorize(@community_solution || @community_solutions)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_community_solution
    @community_solution = CommunitySolution.find(params[:id])
  end

  def set_community_solution_lock
    @community_solution_lock = CommunitySolutionLock.find(params[:lock_id])
  end

  def set_exercise_and_submission
    @exercise = @community_solution.exercise
    @submission = current_user.submissions.final.where(exercise_id: @community_solution.exercise.id).order('created_at DESC').first
  end
end
