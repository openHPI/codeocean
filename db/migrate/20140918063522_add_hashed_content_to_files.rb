# frozen_string_literal: true

class AddHashedContentToFiles < ActiveRecord::Migration[4.2]
  class CodeOcean::File < ApplicationRecord
    before_validation :hash_content, if: :content_present?

    private

    def content_present?
      content? || native_file?
    end

    def hash_content
      self.hashed_content = Digest::MD5.new.hexdigest(read || '')
    end
  end

  def change
    add_column :files, :hashed_content, :string

    reversible do |direction|
      direction.up do
        CodeOcean::File.unscope(:order).find_each(&:save)
      end
    end
  end
end
