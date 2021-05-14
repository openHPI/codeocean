# frozen_string_literal: true

class FileTemplatePolicy < AdminOnlyPolicy
  def by_file_type?
    everyone
  end
end
