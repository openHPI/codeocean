# frozen_string_literal: true

class Comment < ApplicationRecord
  # inherit the creation module: encapsulates that this is a polymorphic user, offers some aliases and makes sure that all necessary attributes are set.
  include Creation
  include ActionCableHelper

  attr_accessor :username, :date, :updated, :editable

  belongs_to :file, class_name: 'CodeOcean::File'
  belongs_to :user, polymorphic: true
  # after_save :trigger_rfc_action_cable_from_comment

  def request_for_comment
    RequestForComment.find_by(submission_id: file.context.id)
  end

  def only_comment_for_rfc?
    request_for_comment.comments.one?
  end
end
