# frozen_string_literal: true

class AddFileIndexToFiles < ActiveRecord::Migration[4.2]
  def change
    add_index(:files, %i[context_id context_type])
  end
end
