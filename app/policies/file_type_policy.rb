class FileTypePolicy < AdminOnlyPolicy
  def author?
    @user == @record.author
  end
  private :author?

  [:create?, :index?, :new?].each do |action|
    define_method(action) { admin? || teacher? }
  end

end
