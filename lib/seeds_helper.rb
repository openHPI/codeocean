# frozen_string_literal: true

module SeedsHelper
  def self.read_seed_file(filename)
    file = File.new(seed_file_path(filename), 'r')
    content = file.read
    file.close
    content
  end

  def self.seed_file_path(filename)
    Rails.root.join('db', 'seeds', filename)
  end
end
