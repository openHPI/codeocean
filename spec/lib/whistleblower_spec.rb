require 'rails_helper'

describe Whistleblower do
  let(:hint) { FactoryBot.create(:ruby_no_method_error) }
  let(:stderr) { "undefined method `foo' for main:Object (NoMethodError)" }
  let(:whistleblower) { described_class.new(execution_environment: hint.execution_environment) }

  describe '#find_hint' do
    let(:find_hint) { whistleblower.send(:find_hint, stderr) }

    it 'finds the hint' do
      expect(find_hint).to eq(hint)
    end

    it 'stores the matches' do
      find_hint
      expect(whistleblower.instance_variable_get(:@matches)).to be_a(MatchData)
    end
  end

  describe '#generate_hint' do
    it 'returns the customized hint message' do
      message = whistleblower.generate_hint(stderr)
      expect(message[0..9]).to eq(hint.message[0..9])
      expect(message[-10..-1]).to eq(hint.message[-10..-1])
    end
  end
end
