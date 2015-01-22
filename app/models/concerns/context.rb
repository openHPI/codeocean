module Context
  extend ActiveSupport::Concern

  included do
    has_many :files, as: :context, class: CodeOcean::File
    accepts_nested_attributes_for :files
  end

  def add_file(file_attributes)
    file = files.create(file_attributes)
    save
    file
  end

  def add_file!(file_attributes)
    file = files.create!(file_attributes)
    save!
    file
  end
end
