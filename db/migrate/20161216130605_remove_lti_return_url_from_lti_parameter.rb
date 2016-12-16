class RemoveLtiReturnUrlFromLtiParameter < ActiveRecord::Migration
  def change
    remove_column :lti_parameters, :lti_return_url, :text
  end
end
