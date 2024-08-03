# frozen_string_literal: true

class FileTemplatePolicy < AdminOnlyPolicy
  %i[index? show?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  def by_file_type?
    everyone
  end
end
