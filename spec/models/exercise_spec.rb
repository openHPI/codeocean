require 'rails_helper'

describe Exercise do
  let(:exercise) { described_class.create.tap { |exercise| exercise.update(public: nil, token: nil) } }

  it 'validates the presence of a description' do
    expect(exercise.errors[:description]).to be_present
  end

  it 'validates the presence of an execution environment' do
    expect(exercise.errors[:execution_environment_id]).to be_present
  end

  it 'validates the presence of the public flag' do
    expect(exercise.errors[:public]).to be_present
  end

  it 'validates the presence of a title' do
    expect(exercise.errors[:title]).to be_present
  end

  it 'validates the presence of a token' do
    expect(exercise.errors[:token]).to be_present
  end

  it 'validates the presence of a user' do
    expect(exercise.errors[:user_id]).to be_present
    expect(exercise.errors[:user_type]).to be_present
  end

  describe '#duplicate' do
    let(:exercise) { FactoryGirl.create(:fibonacci) }
    after(:each) { exercise.duplicate }

    it 'duplicates the exercise' do
      expect(exercise).to receive(:dup).and_call_original
    end

    it 'overwrites the supplied attributes' do
      title = Forgery(:basic).text
      expect(exercise.duplicate(title: title).title).to eq(title)
    end

    it 'duplicates all associated files' do
      exercise.files.each do |file|
        expect(file).to receive(:dup).and_call_original
      end
    end

    it 'returns the duplicated exercise' do
      expect(exercise.duplicate).to be_a(described_class)
    end
  end
end
