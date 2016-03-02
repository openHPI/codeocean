class CreateCodeHarborLinks < ActiveRecord::Migration
  def change
    create_table :code_harbor_links do |t|
      t.string :oauth2token

      t.timestamps
    end
  end
end
