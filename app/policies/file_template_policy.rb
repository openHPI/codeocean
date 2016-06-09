class FileTemplatePolicy < AdminOnlyPolicy

  def show?
    everyone
  end

end
