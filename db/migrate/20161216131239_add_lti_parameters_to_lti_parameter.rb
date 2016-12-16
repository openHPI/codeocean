class AddLtiParametersToLtiParameter < ActiveRecord::Migration
  def change
    add_column :lti_parameters, :lti_parameters, :json
  end
end
