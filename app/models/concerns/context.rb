# frozen_string_literal: true

module Context
  extend ActiveSupport::Concern

  included do
    has_many :files, as: :context, class_name: 'CodeOcean::File'
    accepts_nested_attributes_for :files
  end

  def add_file(file_attributes)
    files.create(file_attributes).tap { save }
  end

  def add_file!(file_attributes)
    files.create!(file_attributes).tap { save! }
  end
end
