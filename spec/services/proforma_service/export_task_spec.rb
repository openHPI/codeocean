# frozen_string_literal: true

require 'rails_helper'

describe ProformaService::ExportTask do
  describe '.new' do
    subject(:export_task) { described_class.new(exercise:) }

    let(:exercise) { build(:dummy) }

    it 'assigns exercise' do
      expect(export_task.instance_variable_get(:@exercise)).to be exercise
    end

    context 'without exercise' do
      subject(:export_task) { described_class.new }

      it 'assigns exercise' do
        expect(export_task.instance_variable_get(:@exercise)).to be_nil
      end
    end
  end

  describe '#execute' do
    subject(:export_task) { described_class.call(exercise:) }

    let(:task) { Proforma::Task.new }
    let(:exercise) { build(:dummy) }
    let(:exporter) { instance_double(Proforma::Exporter, perform: 'zip') }

    before do
      allow(ProformaService::ConvertExerciseToTask).to receive(:call).with(exercise:).and_return(task)
      allow(Proforma::Exporter).to receive(:new).with(task:, custom_namespaces: [{prefix: 'CodeOcean', uri: 'codeocean.openhpi.de'}]).and_return(exporter)
    end

    it do
      export_task
      expect(exporter).to have_received(:perform)
    end
  end
end
