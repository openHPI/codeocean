# frozen_string_literal: true

class Subscription < ApplicationRecord
  include Creation
  belongs_to :request_for_comment
  belongs_to :study_group, optional: true
end
