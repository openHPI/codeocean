class AddCauseToTestruns < ActiveRecord::Migration
  def up
    add_column :testruns, :cause, :string
    Testrun.reset_column_information
    Testrun.all.each{ |testrun|
      if(testrun.submission.nil?)
        say_with_time "#{testrun.id} has no submission" do end
      else
        testrun.cause = testrun.submission.cause
        testrun.save
      end
    }
  end

  def down
    remove_column :testruns, :cause
  end
end
