# frozen_string_literal: true

module Api
  module Internal
    class UsersController < Api::ApiController
      def destroy
        user = ExternalUser.where(external_id: params[:id]).first

        return head :not_found unless user

        user.soft_delete
        head :ok
      end
    end
  end
end
