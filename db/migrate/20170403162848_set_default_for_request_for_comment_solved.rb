class SetDefaultForRequestForCommentSolved < ActiveRecord::Migration
  def change
    change_column_default :request_for_comments, :solved, false
    RequestForComment.where(solved: nil).update_all(solved: false)
  end
end