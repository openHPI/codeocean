class UserExerciseFeedbackPolicy < ApplicationPolicy
  def author?
    @user == @record.author
  end
  private :author?

  def create?
    everyone
  end

  def new?
    everyone
  end

  [:show? ,:destroy?, :edit?, :update?].each do |action|
    define_method(action) { admin? || author?}
  end

end
