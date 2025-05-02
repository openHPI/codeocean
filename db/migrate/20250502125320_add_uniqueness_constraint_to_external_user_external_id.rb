# frozen_string_literal: true

class AddUniquenessConstraintToExternalUserExternalId < ActiveRecord::Migration[8.0]
  def change
    Rails.logger.info 'Adding a uniqueness constraint for external IDs associated with external users (and their consumer). ' \
                      'If this fail, resolve the conflicts using `db/scripts/migrate_external_user.sql`'

    change_column_null :external_users, :external_id, false
    add_index :external_users, %i[external_id consumer_id], unique: true
  end
end
