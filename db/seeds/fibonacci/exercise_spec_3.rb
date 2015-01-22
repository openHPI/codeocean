require './exercise'
require './reference'

describe '#fibonacci' do
  SAMPLE_COUNT = 32

  let(:reference) { Class.new.extend(Reference) }

  SAMPLE_COUNT.times do |i|
    instance_eval do
      it "obtains the correct result for input #{i}" do
        expect(fibonacci(i)).to eq(reference.fibonacci(i))
      end
    end
  end
end
