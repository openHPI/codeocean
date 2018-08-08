class ProgrammingLanguagePolicy < AdminOrAuthorPolicy
  def versions?
    admin? || teacher?
  end

  def create?
    admin? || teacher?
  end
end