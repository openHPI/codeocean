# frozen_string_literal: true

require 'rails_helper'

describe CodeOcean::Config do
  describe '#read' do
    let(:content) { {'foo' => 'bar'} }
    let(:filename) { :foo }

    context 'with a .yml file' do
      let(:path) { Rails.root.join('config', "#{filename}.yml") }
      let(:read) { described_class.new(filename).read }

      context 'when the file is present' do
        before { File.write(path, {Rails.env.to_s => content}.to_yaml) }

        after { FileUtils.rm(path) }

        it 'returns the environment-specific content' do
          expect(read).to eq(content.with_indifferent_access)
        end
      end

      context 'when the file is not present' do
        it 'raises an error' do
          expect { read }.to raise_error(CodeOcean::Config::Error)
        end
      end
    end

    context 'with a .yml.erb file' do
      let(:path) { Rails.root.join('config', "#{filename}.yml.erb") }
      let(:read) { described_class.new(filename).read(erb: true) }

      context 'when the file is present' do
        before { File.write(path, {Rails.env.to_s => content}.to_yaml) }

        after { FileUtils.rm(path) }

        it 'returns the environment-specific content' do
          expect(read).to eq(content.with_indifferent_access)
        end
      end

      context 'when the file is not present' do
        it 'raises an error' do
          expect { read }.to raise_error(CodeOcean::Config::Error)
        end
      end
    end
  end
end
