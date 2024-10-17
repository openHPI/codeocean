# frozen_string_literal: true

module RansackObject
  # Case insensitive search with Postgres and Ransack.
  # Adapted from https://activerecord-hackery.github.io/ransack/getting-started/simple-mode/#case-insensitive-sorting-in-postgresql
  def self.included(base)
    base.columns.each do |column|
      next unless column.type == :string

      base.ransacker column.name.to_sym, type: :string do
        Arel::Nodes::NamedFunction.new('LOWER', [base.arel_table[column.name]])
      end
    end
  end
end
