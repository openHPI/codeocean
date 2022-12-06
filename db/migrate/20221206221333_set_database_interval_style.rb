# frozen_string_literal: true

class SetDatabaseIntervalStyle < ActiveRecord::Migration[7.0]
  # We set the intervalstyle to ISO 8601 for the current database.
  # Without this change, a transaction-based PgBouncer might cause
  # issues with when switching between different sessions (e.g., by
  # returning intervals in the default intervalstyle).

  def change
    connection = ActiveRecord::Base.connection
    dbname = connection.current_database

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          ALTER DATABASE "#{dbname}" SET intervalstyle = 'iso_8601';
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          ALTER DATABASE "#{dbname}" SET intervalstyle = 'postgres';
        SQL
      end
    end
  end
end
