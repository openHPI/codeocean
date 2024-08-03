# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def show?
    everyone
  end

  %i[new? destroy? update? edit?].each do |action|
    define_method(action) { admin? || author? || teacher_in_study_group? }
  end

  def index?
    everyone
  end
end
