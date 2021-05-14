# frozen_string_literal: true

class AddIndexForLtiParametersExternalUserId < ActiveRecord::Migration[4.2]
  def change
    add_index :lti_parameters, :external_users_id
  end
end
