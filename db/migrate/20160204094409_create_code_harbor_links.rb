# frozen_string_literal: true

class CreateCodeHarborLinks < ActiveRecord::Migration[4.2]
  def change
    create_table :code_harbor_links do |t|
      t.string :oauth2token

      t.timestamps
    end
  end
end
