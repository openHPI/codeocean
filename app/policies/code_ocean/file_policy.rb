# frozen_string_literal: true

module CodeOcean
  class FilePolicy < AdminOrAuthorPolicy
    def author?
      @user == @record.context.author
    end

    def show?
      return false if @record.native_file? && !@record.native_file_location_valid?

      if @record.context.is_a?(Exercise)
        admin? || author? || !@record.hidden
      else
        admin? || author?
      end
    end

    def show_protected_upload?
      return false if @record.native_file? && !@record.native_file_location_valid?

      if @record.context.is_a?(Exercise)
        admin? || author? || (!@record.context.unpublished && !@record.hidden)
      else
        admin? || author?
      end
    end

    def create?
      if @record.context.is_a?(Exercise)
        admin? || author?
      elsif @record.context.is_a?(Submission) && @record.context.exercise.allow_file_creation
        author?
      else
        no_one
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
