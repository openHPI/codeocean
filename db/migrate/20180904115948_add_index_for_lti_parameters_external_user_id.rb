class AddIndexForLtiParametersExternalUserId < ActiveRecord::Migration
  def change
    add_index :lti_parameters, :external_users_id
  end
end
