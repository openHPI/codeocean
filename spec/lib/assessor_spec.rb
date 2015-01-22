require 'rails_helper'

describe Assessor do
  describe '#calculate_score' do
    let(:count) { 42 }
    let(:passed) { 17 }
    let(:test_outcome) { {count: count, passed: passed} }

    context 'with a testing framework adapter' do
      let(:assessor) { Assessor.new(execution_environment: FactoryGirl.build(:ruby)) }

      it 'returns the correct score' do
        expect(assessor.send(:calculate_score, test_outcome)).to eq(passed.to_f / count.to_f)
      end
    end

    context 'without a testing framework adapter' do
      let(:assessor) { Assessor.new(execution_environment: FactoryGirl.build(:execution_environment)) }

      it 'raises an error' do
        expect { assessor.send(:calculate_score, test_outcome) }.to raise_error
      end
    end
  end
end
