class SubmissionPolicy < ApplicationPolicy
  def create?
    everyone
  end

  # insights? is used in the flowr_controller.rb as we use it to authorize the user for a submission
  [:download?, :download_file?, :render_file?, :run?, :score?, :show?, :statistics?, :stop?, :test?, :insights?].each do |action|
    define_method(action) { admin? || author? }
  end

  def index?
    admin?
  end

  def everyone_in_study_group
    users_in_same_study_group = @record.study_groups.users
    users_in_same_study_group.include? @user
  end
  private :everyone_in_study_group

  def teacher_in_study_group
    teacher? && everyone_in_study_group
  end
  private :teacher_in_study_group
end
