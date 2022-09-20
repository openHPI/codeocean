# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :request_for_comment
  belongs_to :study_group, optional: true
end
