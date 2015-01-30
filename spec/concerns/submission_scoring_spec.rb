require 'rails_helper'

class Controller < AnonymousController
  include SubmissionScoring
end

describe SubmissionScoring do
  before(:all) do
    @submission = FactoryGirl.create(:submission, cause: 'submit')
  end

  let(:controller) { Controller.new }
  before(:each) { controller.instance_variable_set(:@current_user, FactoryGirl.create(:external_user)) }

  describe '#score_submission' do
    let(:score_submission) { Proc.new { controller.score_submission(@submission) } }
    before(:each) { score_submission.call }

    it 'assigns @assessor' do
      expect(controller.instance_variable_get(:@assessor)).to be_an(Assessor)
    end

    it 'assigns @docker_client' do
      expect(controller.instance_variable_get(:@docker_client)).to be_a(DockerClient)
    end

    it 'executes the teacher-defined test cases' do
      @submission.collect_files.select(&:teacher_defined_test?).each do |file|
        expect_any_instance_of(DockerClient).to receive(:execute_test_command).with(@submission, file.name_with_extension).and_return({})
      end
      score_submission.call
    end

    it 'updates the submission' do
      expect(@submission).to receive(:update).with(score: anything)
      score_submission.call
    end
  end
end
