# frozen_string_literal: true

class ConsumerPolicy < AdminOnlyPolicy
  class WithInternalUsersScope < Scope
    def resolve
      if @user.admin?
        @scope.where(id: InternalUser.select(:consumer_id))
      elsif @user.teacher?
        @scope.where(id: InternalUserPolicy::Scope.new(@user, InternalUser).resolve.distinct.pluck(:consumer_id))
      else
        @scope.none
      end
    end
  end

  class WithExternalUsersScope < Scope
    def resolve
      if @user.admin?
        @scope.where(id: ExternalUser.select(:consumer_id))
      elsif @user.teacher?
        @scope.where(id: ExternalUserPolicy::Scope.new(@user, ExternalUser).resolve.distinct.pluck(:consumer_id))
      else
        @scope.none
      end
    end
  end

  class WithStudyGroupsScope < Scope
    def resolve
      if @user.admin?
        @scope.where(id: StudyGroup.select(:consumer_id))
      elsif @user.teacher?
        @scope.where(id: StudyGroupPolicy::Scope.new(@user, StudyGroup).resolve.distinct.pluck(:consumer_id))
      else
        @scope.none
      end
    end
  end
end
