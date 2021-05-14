# frozen_string_literal: true

require './exercise'

describe '#fibonacci' do
  it 'works recursively' do
    @n = 16
    expect(self).to receive(:fibonacci).and_call_original.at_least(@n**2).times
    fibonacci(@n)
  end
end
