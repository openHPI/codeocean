class FileTypePolicy < AdminOnlyPolicy
  def author?
    @user == @record.author
  end
  private :author?
end
