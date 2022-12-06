# frozen_string_literal: true

# Adapted from https://github.com/rails/sprockets/issues/502#issuecomment-1030634236

SOURCE_EXTENSIONS = %w[.css .js].freeze

namespace :assets do
  def append_sourcemap
    manifest_path = Dir[Rails.public_path.join('assets/.sprockets-manifest-*.json').to_s].max {|a, b| File.ctime(a) <=> File.ctime(b) }
    return unless manifest_path

    manifest_json = JSON.parse(File.read(manifest_path))
    assets = manifest_json['assets']
    manifest = manifest_json['files']

    assets.each do |name, digested|
      ext = File.extname(name)
      next unless SOURCE_EXTENSIONS.include? ext

      # Get the source map file from the manifest
      map_digested = assets["#{name}.map"]
      next unless map_digested

      # Parse the source map file
      source_map = JSON.parse(File.read(Rails.public_path.join('assets', map_digested).to_s))

      # Replace the source map file name with the digested one
      if source_map['sections'].present?
        source_map['sections'].map! do |section|
          section['map']['sources'].map! {|source| assets[source] || source }
          section
        end
      elsif source_map['sources'].present?
        source_map['sources'].map! {|source| assets[source] || source }
      end

      # Write the source map file
      asset_source = Rails.public_path.join('assets', map_digested).to_s
      write_asset(asset_source, source_map.to_json, manifest)

      # Construct the source map link
      file = Rails.root.join("public/assets/#{digested}")
      mapping_string = "sourceMappingURL=#{map_digested}"

      mapping_string = case ext
                         when '.css' then "/*# #{mapping_string} */"
                         when '.js' then "//# #{mapping_string}"
                       end

      # Read the source map file and append the source map link
      existing_file_content = file.readlines.map(&:strip)

      if existing_file_content.blank? || existing_file_content[-1] == mapping_string
        # Just "restore" the integrity hash
        mtime = Sprockets::PathUtils.stat(file)&.mtime
        manifest[File.basename(file)].merge!(changed_manifest(existing_file_content.join("\n"), mtime))
      else
        # Append the source map link to the file
        new_content = existing_file_content + [mapping_string]
        write_asset(file, new_content.join("\n"), manifest)
      end
    end

    # We need to write the manifest file again to include the new integrity hashes
    manifest_json['files'] = manifest
    File.write(manifest_path, manifest_json.to_json)
  end

  def write_asset(filename, content, manifest)
    File.write(filename, content)
    mtime = Sprockets::PathUtils.stat(filename)&.mtime
    compress_asset(filename, content, mtime)
    manifest[File.basename(filename)].merge!(changed_manifest(content, mtime))
  end

  def compress_asset(source_filename, content, mtime)
    target = "#{source_filename}.gz"

    File.open(target, 'wb') do |file|
      Sprockets::Utils::Gzip::ZlibArchiver.call(file, content, mtime)
    end
  end

  def changed_manifest(content, mtime)
    digest = Sprockets::DigestUtils.digest(content)
    hexdigest = Sprockets::DigestUtils.pack_hexdigest(digest)

    {
      'mtime' => mtime,
      'size' => content.bytesize,
      'digest' => hexdigest,
      'integrity' => Sprockets::DigestUtils.hexdigest_integrity_uri(hexdigest),
    }
  end

  task precompile: :environment do
    append_sourcemap
  end
end
