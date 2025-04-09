# frozen_string_literal: true

module ProformaService
  class UuidFromZip < ServiceBase
    def initialize(zip:)
      super()
      @zip = zip
    end

    def execute
      if xml_exists_in_zip?
        importer = ProformaXML::Importer.new(zip: @zip)
        import_result = importer.perform
        task = import_result
        task.uuid
      end
    rescue Zip::Error
      raise ProformaXML::InvalidZip.new I18n.t('exercises.import_proforma.import_errors.invalid_zip')
    end

    private

    def xml_exists_in_zip?
      filenames = Zip::File.open(@zip.path) do |zip_file|
        zip_file.map(&:name)
      end

      return true if filenames.any? {|f| f[/\.xml$/] }

      raise ProformaXML::InvalidZip.new I18n.t('exercises.import_proforma.import_errors.no_xml_found')
    end
  end
end
