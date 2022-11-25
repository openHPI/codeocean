# frozen_string_literal: true

require 'rails_helper'

describe Submission do
  let(:submission) { create(:submission, exercise: create(:dummy)) }

  it 'validates the presence of a cause' do
    expect(described_class.create.errors[:cause]).to be_present
  end

  it 'validates the presence of an exercise' do
    expect(described_class.create.errors[:exercise]).to be_present
  end

  it 'validates the presence of a user' do
    expect(described_class.create.errors[:user]).to be_present
  end

  describe '#main_file' do
    let(:submission) { create(:submission) }

    it "returns the submission's main file" do
      expect(submission.main_file).to be_a(CodeOcean::File)
      expect(submission.main_file.main_file?).to be true
    end
  end

  describe '#normalized_score' do
    context 'with a score' do
      let(:submission) { create(:submission) }

      before { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score as a value between 0 and 1' do
        expect(submission.normalized_score).to be_between(0, 1)
      end
    end

    context 'without a score' do
      before { submission.score = nil }

      it 'returns 0' do
        expect(submission.normalized_score).to be 0
      end
    end
  end

  describe '#percentage' do
    context 'with a score' do
      let(:submission) { create(:submission) }

      before { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score expressed as a percentage' do
        expect(submission.percentage).to be_between(0, 100)
      end
    end

    context 'without a score' do
      before { submission.score = nil }

      it 'returns 0' do
        expect(submission.percentage).to be 0
      end
    end
  end

  describe '#siblings' do
    let(:siblings) { described_class.find_by(user:).siblings }
    let(:user) { create(:external_user) }

    before do
      10.times.each_with_index do |_, index|
        create(:submission, exercise: submission.exercise, user: (index.even? ? user : create(:external_user)))
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
      let(:exercise) { create(:dummy) }
      let(:user) { build(:external_user, id: (11 - (exercise.created_at.to_i % 10)) % 10) }
      let(:submission) { build(:submission, exercise:, user:) }

      it 'sends 10% of users to feedback page' do
        expect(submission.send(:redirect_to_feedback?)).to be_truthy
      end

      it 'does not redirect other users' do
        9.times do |i|
          submission = build(:submission, exercise:, user: build(:external_user, id: (11 - (exercise.created_at.to_i % 10)) - i - 1))
          expect(submission.send(:redirect_to_feedback?)).to be_falsey
        end
      end
    end

    context 'with little exercise feedback' do
      let(:exercise) { create(:dummy_with_user_feedbacks) }
      let(:user) { build(:external_user, id: (11 - (exercise.created_at.to_i % 10)) % 10) }
      let(:submission) { build(:submission, exercise:, user:) }

      it 'sends 10% of users to feedback page' do
        expect(submission.send(:redirect_to_feedback?)).to be_truthy
      end

      it 'does not redirect other users' do
        9.times do |i|
          submission = build(:submission, exercise:, user: build(:external_user, id: (11 - (exercise.created_at.to_i % 10)) - i - 1))
          expect(submission.send(:redirect_to_feedback?)).to be_falsey
        end
      end
    end
  end

  describe '#calculate_score' do
    let(:runner) { create(:runner) }

    before do
      allow(Runner).to receive(:for).and_return(runner)
      allow(runner).to receive(:copy_files)
      allow(runner).to receive(:attach_to_execution).and_return(1.0)
    end

    after { submission.calculate_score }

    it 'executes every teacher-defined test file' do
      allow(submission).to receive(:combine_file_scores)
      submission.collect_files.select(&:teacher_defined_assessment?).each do |file|
        expect(submission).to receive(:score_file).with(any_args, file)
      end
    end

    it 'scores the submission' do
      expect(submission).to receive(:combine_file_scores)
    end
  end

  describe '#combine_file_scores' do
    after { submission.send(:combine_file_scores, []) }

    it 'assigns a score to the submissions' do
      expect(submission).to receive(:update).with(score: anything)
    end
  end
end
