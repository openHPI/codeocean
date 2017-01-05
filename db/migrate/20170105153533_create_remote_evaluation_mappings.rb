class CreateRemoteEvaluationMappings < ActiveRecord::Migration
  def change
    create_table :remote_evaluation_mappings do |t|

      t.timestamps
    end
  end
end
