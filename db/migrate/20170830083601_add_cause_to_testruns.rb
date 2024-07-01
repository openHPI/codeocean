# frozen_string_literal: true

class AddCauseToTestruns < ActiveRecord::Migration[4.2]
  class Testrun < ApplicationRecord
    belongs_to :submission, optional: true
  end

  class Submission < ApplicationRecord
  end

  def up
    add_column :testruns, :cause, :string
    Testrun.reset_column_information
    Testrun.find_each do |testrun|
      if testrun.submission.nil?
        say_with_time "#{testrun.id} has no submission"
      else
        testrun.cause = testrun.submission.cause
        testrun.save
      end
    end
  end

  def down
    remove_column :testruns, :cause
  end
end
