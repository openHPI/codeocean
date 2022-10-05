# frozen_string_literal: true

module CodeOcean
  class FilePolicy < AdminOrAuthorPolicy
    def author?
      @user == @record.context&.author
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

    def render_protected_upload?
      return no_one if @record.native_file? && !@record.native_file_location_valid?
      return no_one if @record.context.is_a?(Exercise) && (@record.context.unpublished || @record.hidden)

      # The AuthenticatedUrlHelper will check for more details, but we cannot determine a specific user
      everyone
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
