# frozen_string_literal: true

class DeleteInvalidAssessTestruns < ActiveRecord::Migration[8.0]
  class Testrun < ApplicationRecord
  end

  disable_ddl_transaction!

  def change
    # In commit 9c3ec3c (2023-02-17), we introduced a bug, which added an additional undesired assess testrun with no 'passed' value.
    # We fixed this bug in 264927e (2023-07-15), but haven't removed the invalid testruns yet.
    Testrun.where(cause: 'assess', passed: nil, file_id: nil).delete_all
  end
end
