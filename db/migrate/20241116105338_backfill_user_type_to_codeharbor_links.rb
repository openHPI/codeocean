# frozen_string_literal: true

class BackfillUserTypeToCodeharborLinks < ActiveRecord::Migration[7.2]
  class CodeharborLink < ApplicationRecord
  end

  class InternalUser < ApplicationRecord
  end

  disable_ddl_transaction!

  def change
    CodeharborLink.where(user_type: nil).update_all(user_type: InternalUser.name.demodulize) # rubocop:disable Rails/SkipsModelValidations
  end
end
