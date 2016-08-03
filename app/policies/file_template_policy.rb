class FileTemplatePolicy < AdminOnlyPolicy

  def show?
    everyone
  end

  def by_file_type?
    everyone
  end

end
