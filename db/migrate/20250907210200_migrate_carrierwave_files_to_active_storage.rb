# frozen_string_literal: true

class MigrateCarrierwaveFilesToActiveStorage < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  module CodeOcean
    class File < ActiveRecord::Base
      self.table_name = 'files'

      # Manually set class name to avoid problems with ActiveStorage's polymorphic association
      def self.name = 'CodeOcean::File'

      has_one_attached :attachment
    end
  end

  def up
    say_with_time 'Migrating CarrierWave files to ActiveStorage' do
      migrated = 0
      skipped_existing = 0
      missing = 0

      scope = CodeOcean::File.unscoped.where.not(native_file: [nil, ''])
      total = scope.count

      scope.find_in_batches(batch_size: 1000).with_index do |batch, i|
        say "Processing batch ##{i + 1} (#{[(i * 1000) + 1, total].min}-#{[(i + 1) * 1000, total].min} of #{total})", true
        batch.each do |record|
          if record.attachment.attached?
            skipped_existing += 1
            next
          end

          filename = record[:native_file]
          next if filename.blank?

          old_path = Rails.public_path.join('uploads', 'files', record.id.to_s, filename)

          unless ::File.exist?(old_path)
            missing += 1
            next
          end

          begin
            File.open(old_path, 'rb') do |io|
              record.attachment.attach(io:, filename: filename)
            end
            migrated += 1
          rescue StandardError => e
            warn "Failed to attach file for files.id=#{record.id}: #{e.class}: #{e.message}"
          end
        end
      end

      say "Done. Migrated: #{migrated}, already attached: #{skipped_existing}, missing source files: #{missing}", true

      migrated
    end
  end

  def down
    say 'No rollback for CarrierWave -> ActiveStorage file migration.'
  end
end
