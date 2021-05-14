# frozen_string_literal: true

require './exercise'

describe '#fibonacci' do
  it 'is defined' do
    expect { method(:fibonacci) }.not_to raise_error
  end

  it 'has the correct arity' do
    expect(method(:fibonacci).arity).to eq(1)
  end

  it 'returns a number' do
    expect(fibonacci(1)).to be_an(Integer)
  end
end
