class AddQuestionToRequestForComments < ActiveRecord::Migration
  def change
    add_column :request_for_comments, :question, :text
  end
end
