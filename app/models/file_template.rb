# frozen_string_literal: true

class FileTemplate < ApplicationRecord
  belongs_to :file_type

  delegate :to_s, to: :name
end
