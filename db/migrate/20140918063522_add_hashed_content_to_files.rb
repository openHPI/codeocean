# frozen_string_literal: true

class AddHashedContentToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :hashed_content, :string

    reversible do |direction|
      direction.up do
        CodeOcean::File.all.each(&:save)
      end
    end
  end
end
