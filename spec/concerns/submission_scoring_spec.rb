require 'rails_helper'

class Controller < AnonymousController
  include SubmissionScoring
end

describe SubmissionScoring do
  let(:controller) { Controller.new }
  before(:all) { @submission = FactoryBot.create(:submission, cause: 'submit') }
  before(:each) { controller.instance_variable_set(:@current_user, FactoryBot.create(:external_user)) }

  describe '#collect_test_results' do
    after(:each) { controller.send(:collect_test_results, @submission) }

    it 'executes every teacher-defined test file' do
      @submission.collect_files.select(&:teacher_defined_test?).each do |file|
        expect(controller).to receive(:execute_test_file).with(file, @submission).and_return({})
      end
    end
  end

  describe '#score_submission' do
    after(:each) { controller.score_submission(@submission) }

    it 'collects the test results' do
      expect(controller).to receive(:collect_test_results).and_return([])
    end

    it 'assigns a score to the submissions' do
      expect(@submission).to receive(:update).with(score: anything)
    end
  end
end
