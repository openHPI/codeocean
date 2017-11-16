require 'rails_helper'

describe Assessor do
  let(:assessor) { described_class.new(execution_environment: FactoryBot.build(:ruby)) }

  describe '#assess' do
    let(:assess) { assessor.assess(stdout: stdout) }
    let(:stdout) { "Finished in 0.1 seconds (files took 0.1 seconds to load)\n2 examples, 1 failure" }

    context 'when an error occurs' do
      before(:each) do
        expect_any_instance_of(TestingFrameworkAdapter).to receive(:test_outcome).and_raise
      end

      it 'catches the error' do
        expect { assess }.not_to raise_error
      end

      it 'returns a score of zero' do
        expect(assess).to eq(score: 0)
      end
    end

    context 'when no error occurs' do
      after(:each) { assess }

      it 'utilizes the testing framework adapter' do
        expect(assessor.instance_variable_get(:@testing_framework_adapter)).to receive(:test_outcome)
      end

      it 'calculates the score' do
        expect(assessor).to receive(:calculate_score)
      end
    end
  end

  describe '#calculate_score' do
    let(:count) { 42 }
    let(:passed) { 17 }
    let(:test_outcome) { {count: count, passed: passed} }

    it 'returns the correct score' do
      expect(assessor.send(:calculate_score, test_outcome)).to eq(passed.to_f / count.to_f)
    end
  end

  describe '#initialize' do
    context 'with an execution environment with a testing framework adapter' do
      it 'assigns the testing framework adapter' do
        expect(assessor.instance_variable_get(:@testing_framework_adapter)).to be_an(RspecAdapter)
      end
    end

    context 'with an execution environment without a testing framework adapter' do
      it 'raises an error' do
        expect { described_class.new(execution_environment: FactoryBot.build(:ruby, testing_framework: nil)) }.to raise_error(Assessor::Error)
      end
    end
  end
end
