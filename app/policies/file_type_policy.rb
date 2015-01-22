class FileTypePolicy < AdminOrAuthorPolicy
  def author?
    @user == @record.author
  end
  private :author?
end
