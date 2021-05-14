# frozen_string_literal: true

require './exercise'
require './reference'

describe '#fibonacci' do
  let(:sample_count) { 32 }

  let(:reference) { Class.new.extend(Reference) }

  sample_count.times do |i|
    instance_eval do
      it "obtains the correct result for input #{i}" do
        expect(fibonacci(i)).to eq(reference.fibonacci(i))
      end
    end
  end
end
