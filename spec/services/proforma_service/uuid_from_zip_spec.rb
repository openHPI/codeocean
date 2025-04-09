# frozen_string_literal: true

require 'rails_helper'
require 'zip'

RSpec.describe ProformaService::UuidFromZip do
  describe '.new' do
    subject(:service) { described_class.new(zip:) }

    let(:zip) { Tempfile.new('proforma_test_zip_file') }

    it 'assigns zip' do
      expect(service.instance_variable_get(:@zip)).to be zip
    end
  end

  describe '#execute' do
    subject(:service) { described_class.call(zip: service_input) }

    let(:valid_zip_file) { Rails.root.join('spec/fixtures/files/proforma_import/testfile.zip').open }
    let(:empty_zip_file) { Rails.root.join('spec/fixtures/files/proforma_import/empty.zip').open }
    let(:corrupt_zip_file) { Rails.root.join('spec/fixtures/files/proforma_import/corrupt.zip').open }

    context 'when the ZIP contains a valid XML file' do
      let(:service_input) { valid_zip_file }
      let(:importer_double) { instance_double(ProformaXML::Importer, perform: instance_double(ProformaXML::Task, uuid: '12345')) }

      it 'returns the task UUID' do
        allow(ProformaXML::Importer).to receive(:new).with(zip: valid_zip_file).and_return(importer_double)

        expect(service).to eq('12345')
      end
    end

    context 'when the ZIP does not contain an XML file' do
      let(:service_input) { empty_zip_file }

      it 'raises a ProformaXML::InvalidZip error with correct message' do
        expect { service }.to raise_error(ProformaXML::InvalidZip, I18n.t('exercises.import_proforma.import_errors.no_xml_found'))
      end
    end

    context 'when the ZIP file cannot be opened' do
      let(:service_input) { corrupt_zip_file }

      it 'raises a ProformaXML::InvalidZip with correct message' do
        expect { service }.to raise_error(ProformaXML::InvalidZip, I18n.t('exercises.import_proforma.import_errors.invalid_zip'))
      end
    end
  end
end
