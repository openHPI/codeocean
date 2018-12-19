module CodeOcean
  class FilePolicy < AdminOrAuthorPolicy
    def author?
      @user == @record.context.author
    end

    def show?
      if @record.context.is_a?(Exercise)
        admin? || author? || !@record.hidden
      else
        admin? || author?
      end
    end

    def create?
      if @record.context.is_a?(Exercise)
        admin? || author?
      else
        author?
      end
    end

    def destroy?
      if @record.context.is_a?(Exercise)
        admin? || author?
      else
        no_one
      end
    end
  end
end
