# frozen_string_literal: true

require 'rails_helper'

describe Exercise do
  let(:exercise) { described_class.create.tap {|exercise| exercise.update(public: nil, token: nil) } }
  let(:users) { create_list(:external_user, 10) }

  def create_submissions
    create_list(:submission, 10, cause: 'submit', exercise:, score: Forgery(:basic).number, user: users.sample)
  end

  it 'validates the number of main files' do
    exercise = create(:dummy)
    exercise.files += create_pair(:file)
    expect(exercise).to receive(:valid_main_file?).and_call_original
    exercise.save
    expect(exercise.errors[:files]).to be_present
  end

  it 'validates the presence of a description' do
    expect(exercise.errors[:description]).to be_present
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
    expect(exercise.errors[:user]).to be_present
  end

  context 'when exercise is unpublished' do
    subject { build(:dummy, unpublished: true) }

    it { is_expected.not_to validate_presence_of(:execution_environment) }
  end

  context 'when exercise is not unpublished' do
    subject { build(:dummy, unpublished: false) }

    it { is_expected.to validate_presence_of(:execution_environment) }
  end

  context 'with uuid' do
    subject { build(:dummy, uuid: SecureRandom.uuid) }

    it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }
  end

  context 'without uuid' do
    subject { build(:dummy, uuid: nil) }

    it { is_expected.not_to validate_uniqueness_of(:uuid) }
  end

  describe '#average_percentage' do
    let(:exercise) { create(:fibonacci) }

    context 'without submissions' do
      it 'returns nil' do
        expect(exercise.average_percentage).to be 0
      end
    end

    context 'with submissions' do
      before { create_submissions }

      it 'returns the average score expressed as a percentage' do
        maximum_percentages = exercise.submissions.group_by(&:user_id).values.map {|submission| submission.max_by(&:score).score / exercise.maximum_score * 100 }
        expect(exercise.average_percentage).to eq(maximum_percentages.average.round(2))
      end
    end
  end

  describe '#average_score' do
    let(:exercise) { create(:fibonacci) }

    context 'without submissions' do
      it 'returns nil' do
        expect(exercise.average_score).to be 0
      end
    end

    context 'with submissions' do
      before { create_submissions }

      it "returns the average of all users' maximum scores" do
        maximum_scores = exercise.submissions.group_by(&:user_id).values.map {|submission| submission.max_by(&:score).score }
        expect(exercise.average_score).to be_within(0.1).of(maximum_scores.average)
      end
    end
  end

  describe '#duplicate' do
    let(:exercise) { create(:fibonacci) }

    after { exercise.duplicate }

    it 'duplicates the exercise' do
      expect(exercise).to receive(:dup).and_call_original
    end

    it 'overwrites the supplied attributes' do
      title = Forgery(:basic).text
      expect(exercise.duplicate(title:).title).to eq(title)
    end

    it 'duplicates all associated files' do
      expect(exercise.files).to all(receive(:dup).and_call_original)
    end

    it 'returns the duplicated exercise' do
      expect(exercise.duplicate).to be_a(described_class)
    end
  end

  describe '#teacher_defined_assessment?' do
    let(:exercise) { create(:dummy) }

    context 'when no assessment is defined' do
      it 'returns false' do
        expect(exercise).not_to be_teacher_defined_assessment
      end
    end

    context 'when unit tests are defined' do
      before { create(:test_file, context: exercise) }

      it 'returns true' do
        expect(exercise).to be_teacher_defined_assessment
      end
    end

    context 'when linter tests are defined' do
      before { create(:test_file, context: exercise, role: 'teacher_defined_linter') }

      it 'returns true' do
        expect(exercise).to be_teacher_defined_assessment
      end
    end

    context 'when unit and linter tests are defined' do
      before do
        create(:test_file, context: exercise)
        create(:test_file, context: exercise, role: 'teacher_defined_linter')
      end

      it 'returns true' do
        expect(exercise).to be_teacher_defined_assessment
      end
    end
  end
end
