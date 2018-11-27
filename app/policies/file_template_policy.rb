class FileTemplatePolicy < AdminOnlyPolicy

  def index?
    admin? || teacher?
  end

  def show?
    admin? || teacher?
  end

  def by_file_type?
    everyone
  end

end
