# frozen_string_literal: true

class Comment < ApplicationRecord
  # inherit the creation module: encapsulates that this is a polymorphic user, offers some aliases and makes sure that all necessary attributes are set.
  include Creation
  include ActionCableHelper

  attr_accessor :username, :date, :updated, :editable

  belongs_to :file, class_name: 'CodeOcean::File'
  has_one :submission, through: :file, source: :context, source_type: 'Submission'
  has_one :request_for_comment, through: :submission
  # after_save :trigger_rfc_action_cable_from_comment

  def only_comment_for_rfc?
    request_for_comment.comments.one?
  end
end
