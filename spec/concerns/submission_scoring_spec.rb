# frozen_string_literal: true

require 'rails_helper'

describe SubmissionScoring do
  let(:submission) { FactoryBot.create(:submission, cause: 'submit') }

  describe '#collect_test_results' do
    let(:runner) { FactoryBot.create :runner }

    before do
      allow(Runner).to receive(:for).and_return(runner)
      allow(runner).to receive(:copy_files)
      allow(runner).to receive(:execute_interactively).and_return(1.0)
    end

    after { submission.calculate_score }

    it 'executes every teacher-defined test file' do
      allow(submission).to receive(:score_submission)
      submission.collect_files.select(&:teacher_defined_assessment?).each do |file|
        allow(submission).to receive(:test_result).with(any_args, file).and_return({})
      end
    end

    it 'scores the submission' do
      allow(submission).to receive(:score_submission).and_return([])
    end
  end

  describe '#score_submission', cleaning_strategy: :truncation do
    after { submission.score_submission([]) }

    it 'assigns a score to the submissions' do
      expect(submission).to receive(:update).with(score: anything)
    end
  end
end
