require 'rails_helper'

describe TestingFrameworkAdapter do
  let(:adapter) { described_class.new }
  let(:count) { 42 }
  let(:failed) { 25 }
  let(:passed) { 17 }

  describe '#augment_output' do
    context 'when missing the count of all tests' do
      it 'adds the count of all tests' do
        expect(adapter.send(:augment_output, failed: failed, passed: passed)).to include(count: count)
      end
    end

    context 'when missing the count of failed tests' do
      it 'adds the count of failed tests' do
        expect(adapter.send(:augment_output, count: count, passed: passed)).to include(failed: failed)
      end
    end

    context 'when missing the count of passed tests' do
      it 'adds the count of passed tests' do
        expect(adapter.send(:augment_output, count: count, failed: failed)).to include(passed: passed)
      end
    end
  end

  describe '.framework_name' do
    it 'defaults to the class name' do
      expect(adapter.class.framework_name).to eq(described_class.name)
    end
  end

  describe '#parse_output' do
    it 'requires subclasses to implement #parse_output' do
      expect { adapter.send(:parse_output, '') }.to raise_error(NotImplementedError)
    end
  end

  describe '#test_outcome' do
    it 'calls the framework-specific implementation' do
      expect(adapter).to receive(:parse_output).and_return(count: count, failed: failed, passed: passed)
      adapter.test_outcome('')
    end
  end
end
