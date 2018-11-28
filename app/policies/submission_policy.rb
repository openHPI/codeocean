class SubmissionPolicy < ApplicationPolicy
  def author?
    @user == @record.author
  end
  private :author?

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
end
