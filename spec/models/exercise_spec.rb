require 'rails_helper'

describe Exercise do
  let(:exercise) { described_class.create.tap { |exercise| exercise.update(public: nil, token: nil) } }
  let(:users) { FactoryBot.create_list(:external_user, 10) }

  def create_submissions
    10.times do
      FactoryBot.create(:submission, cause: 'submit', exercise: exercise, score: Forgery(:basic).number, user: users.sample)
    end
  end

  it 'validates the number of main files' do
    exercise = FactoryBot.create(:dummy)
    exercise.files += FactoryBot.create_pair(:file)
    expect(exercise).to receive(:valid_main_file?).and_call_original
    exercise.save
    expect(exercise.errors[:files]).to be_present
  end

  it 'validates the presence of a description' do
    expect(exercise.errors[:description]).to be_present
  end

  it 'validates the presence of an execution environment' do
    expect(exercise.errors[:execution_environment_id]).to be_present
  end

  it 'validates the presence of the public flag' do
    expect(exercise.errors[:public]).to be_present
    exercise.update(public: false)
    expect(exercise.errors[:public]).to be_blank
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

  describe '#average_percentage' do
    let(:exercise) { FactoryBot.create(:fibonacci) }

    context 'without submissions' do
      it 'returns nil' do
        expect(exercise.average_percentage).to be 0
      end
    end

    context 'with submissions' do
      before(:each) { create_submissions }

      it 'returns the average score expressed as a percentage' do
        maximum_percentages = exercise.submissions.group_by(&:user_id).values.map { |submission| submission.sort_by(&:score).last.score / exercise.maximum_score * 100 }
        expect(exercise.average_percentage).to eq(maximum_percentages.average.round)
      end
    end
  end

  describe '#average_score' do
    let(:exercise) { FactoryBot.create(:fibonacci) }

    context 'without submissions' do
      it 'returns nil' do
        expect(exercise.average_score).to be 0
      end
    end

    context 'with submissions' do
      before(:each) { create_submissions }

      it "returns the average of all users' maximum scores" do
        maximum_scores = exercise.submissions.group_by(&:user_id).values.map { |submission| submission.sort_by(&:score).last.score }
        expect(exercise.average_score).to be_within(0.1).of(maximum_scores.average)
      end
    end
  end

  describe '#duplicate' do
    let(:exercise) { FactoryBot.create(:fibonacci) }
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
