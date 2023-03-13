# frozen_string_literal: true

require 'rails_helper'

class Controller < AnonymousController
  include FileParameters
end

describe FileParameters do
  let(:controller) { Controller.new }
  let(:hello_world) { create(:hello_world) }

  describe '#reject_illegal_file_attributes!' do
    def file_accepted?(file)
      files = {'0': attributes_for(:file, context: hello_world, file_id: file.id)}
      filtered_files = controller.send(:reject_illegal_file_attributes, hello_world, files)
      files.eql?(filtered_files)
    end

    describe 'accepts' do
      it 'main file of the exercise' do
        main_file = hello_world.files.find {|e| e.role = 'main_file' }
        expect(file_accepted?(main_file)).to be true
      end

      it 'new file' do
        submission = create(:submission, exercise: hello_world, id: 1337)
        controller.instance_variable_set(:@current_user, submission.user)

        new_file = create(:file, context: submission)
        expect(file_accepted?(new_file)).to be true
      end
    end

    describe 'rejects' do
      it 'file of different exercise' do
        fibonacci = create(:fibonacci, allow_file_creation: true)
        other_exercises_file = create(:file, context: fibonacci)
        expect(file_accepted?(other_exercises_file)).to be false
      end

      it 'hidden file' do
        hidden_file = create(:file, context: hello_world, hidden: true)
        expect(file_accepted?(hidden_file)).to be false
      end

      it 'read-only file' do
        read_only_file = create(:file, context: hello_world, read_only: true)
        expect(file_accepted?(read_only_file)).to be false
      end

      it 'non-existent file' do
        # Ensure to use an invalid id for the file.
        non_existent_file = build(:file, context: hello_world, id: -1)
        expect(file_accepted?(non_existent_file)).to be false
      end

      it 'file of another submission' do
        learner1 = create(:learner)
        learner2 = create(:learner)
        submission_learner1 = create(:submission, exercise: hello_world, user: learner1)
        _submission_learner2 = create(:submission, exercise: hello_world, user: learner2)

        controller.instance_variable_set(:@current_user, learner2)
        other_submissions_file = create(:file, context: submission_learner1)
        expect(file_accepted?(other_submissions_file)).to be false
      end
    end
  end
end
