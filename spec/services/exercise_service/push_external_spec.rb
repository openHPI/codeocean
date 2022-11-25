# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExerciseService::PushExternal do
  describe '.new' do
    subject(:push_external) { described_class.new(zip:, codeharbor_link:) }

    let(:zip) { ProformaService::ExportTask.call(exercise: build(:dummy)) }
    let(:codeharbor_link) { build(:codeharbor_link) }

    it 'assigns zip' do
      expect(push_external.instance_variable_get(:@zip)).to be zip
    end

    it 'assigns codeharbor_link' do
      expect(push_external.instance_variable_get(:@codeharbor_link)).to be codeharbor_link
    end
  end

  describe '#execute' do
    subject(:push_external) { described_class.call(zip:, codeharbor_link:) }

    let(:zip) { ProformaService::ExportTask.call(exercise: build(:dummy)) }
    let(:codeharbor_link) { build(:codeharbor_link) }
    let(:status) { 200 }
    let(:response) { '' }

    before { stub_request(:post, codeharbor_link.push_url).to_return(status:, body: response) }

    it 'calls the correct url' do
      expect(push_external).to have_requested(:post, codeharbor_link.push_url)
    end

    it 'submits the correct headers' do
      expect(push_external).to have_requested(:post, codeharbor_link.push_url)
        .with(headers: {content_type: 'application/zip',
                        authorization: "Bearer #{codeharbor_link.api_key}",
                        content_length: zip.string.length})
    end

    it 'submits the correct body' do
      expect(push_external).to have_requested(:post, codeharbor_link.push_url)
        .with(body: zip.string)
    end

    context 'when response status is success' do
      it { is_expected.to be_nil }

      context 'when response status is 500' do
        let(:status) { 500 }
        let(:response) { 'an error occured' }

        it { is_expected.to be response }
      end
    end

    context 'when an error occurs' do
      before { allow(Faraday).to receive(:new).and_raise(StandardError) }

      it { is_expected.not_to be_nil }
    end
  end
end
