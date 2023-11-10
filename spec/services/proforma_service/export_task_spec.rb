# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProformaService::ExportTask do
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

    let(:task) { ProformaXML::Task.new }
    let(:exercise) { build(:dummy) }
    let(:exporter) { instance_double(ProformaXML::Exporter, perform: 'zip') }

    before do
      allow(ProformaService::ConvertExerciseToTask).to receive(:call).with(exercise:).and_return(task)
      allow(ProformaXML::Exporter).to receive(:new).with(task:).and_return(exporter)
    end

    it do
      export_task
      expect(exporter).to have_received(:perform)
    end
  end
end
