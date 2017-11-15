require 'rails_helper'

describe Submission do
  let(:submission) { FactoryBot.create(:submission, exercise: FactoryBot.create(:dummy)) }

  it 'validates the presence of a cause' do
    expect(described_class.create.errors[:cause]).to be_present
  end

  it 'validates the presence of an exercise' do
    expect(described_class.create.errors[:exercise_id]).to be_present
  end

  it 'validates the presence of a user' do
    expect(described_class.create.errors[:user_id]).to be_present
    expect(described_class.create.errors[:user_type]).to be_present
  end

  describe '#main_file' do
    let(:submission) { FactoryBot.create(:submission) }

    it "returns the submission's main file" do
      expect(submission.main_file).to be_a(CodeOcean::File)
      expect(submission.main_file.main_file?).to be true
    end
  end

  describe '#normalized_score' do
    context 'with a score' do
      let(:submission) { FactoryBot.create(:submission) }
      before(:each) { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score as a value between 0 and 1' do
        expect(0..1).to include(submission.normalized_score)
      end
    end

    context 'without a score' do
      before(:each) { submission.score = nil }

      it 'returns 0' do
        expect(submission.normalized_score).to be 0
      end
    end
  end

  describe '#percentage' do
    context 'with a score' do
      let(:submission) { FactoryBot.create(:submission) }
      before(:each) { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score expressed as a percentage' do
        expect(0..100).to include(submission.percentage)
      end
    end

    context 'without a score' do
      before(:each) { submission.score = nil }

      it 'returns 0' do
        expect(submission.percentage).to be 0
      end
    end
  end

  describe '#siblings' do
    let(:siblings) { described_class.find_by(user: user).siblings }
    let(:user) { FactoryBot.create(:external_user) }

    before(:each) do
      10.times.each_with_index do |_, index|
        FactoryBot.create(:submission, exercise: submission.exercise, user: (index.even? ? user : FactoryBot.create(:external_user)))
      end
    end

    it "returns all the creator's submissions for the same exercise" do
      expect(siblings).to be_an(ActiveRecord::Relation)
      expect(siblings.map(&:exercise).uniq).to eq([submission.exercise])
      expect(siblings.map(&:user).uniq).to eq([user])
    end
  end

  describe '#to_s' do
    it "equals the class' model name" do
      expect(submission.to_s).to eq(described_class.model_name.human)
    end
  end

  describe '#redirect_to_feedback?' do

    context 'with no exercise feedback' do
      let(:exercise) {FactoryBot.create(:dummy)}
      let(:user) {FactoryBot.build(:external_user, id: (11 - exercise.created_at.to_i % 10) % 10)}
      let(:submission) {FactoryBot.build(:submission, exercise: exercise, user: user)}

      it 'sends 10% of users to feedback page' do
        expect(submission.send(:redirect_to_feedback?)).to be_truthy
      end

      it 'does not redirect other users' do
        9.times do |i|
          submission = FactoryBot.build(:submission, exercise: exercise, user: FactoryBot.build(:external_user, id: (11 - exercise.created_at.to_i % 10) - i - 1))
          expect(submission.send(:redirect_to_feedback?)).to be_falsey
        end
      end
    end

    context 'with little exercise feedback' do
      let(:exercise) {FactoryBot.create(:dummy_with_user_feedbacks)}
      let(:user) {FactoryBot.build(:external_user, id: (11 - exercise.created_at.to_i % 10) % 10)}
      let(:submission) {FactoryBot.build(:submission, exercise: exercise, user: user)}

      it 'sends 10% of users to feedback page' do
        expect(submission.send(:redirect_to_feedback?)).to be_truthy
      end

      it 'does not redirect other users' do
        9.times do |i|
          submission = FactoryBot.build(:submission, exercise: exercise, user: FactoryBot.build(:external_user, id: (11 - exercise.created_at.to_i % 10) - i - 1))
          expect(submission.send(:redirect_to_feedback?)).to be_falsey
        end
      end
    end

    context 'with enough exercise feedback' do
      let(:exercise) {FactoryBot.create(:dummy_with_user_feedbacks, user_feedbacks_count: 42)}
      let(:user) {FactoryBot.create(:external_user)}

      it 'sends nobody to feedback page' do
        30.times do |i|
          submission = FactoryBot.create(:submission, exercise: exercise, user: FactoryBot.create(:external_user))
          expect(submission.send(:redirect_to_feedback?)).to be_falsey
        end
      end
    end
  end
end
