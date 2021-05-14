# frozen_string_literal: true

require 'rails_helper'

class Controller < AnonymousController
  include FileParameters
end

describe FileParameters do
  let(:controller) { Controller.new }
  let(:hello_world) { FactoryBot.create(:hello_world) }

  describe '#reject_illegal_file_attributes!' do
    def file_accepted?(file)
      files = [[0, FactoryBot.attributes_for(:file, context: hello_world, file_id: file.id)]]
      filtered_files = controller.send(:reject_illegal_file_attributes, hello_world, files)
      files.eql?(filtered_files)
    end

    describe 'accepts' do
      it 'main file of the exercise' do
        main_file = hello_world.files.find {|e| e.role = 'main_file' }
        expect(file_accepted?(main_file)).to be true
      end

      it 'new file' do
        submission = FactoryBot.create(:submission, exercise: hello_world, id: 1337)
        new_file = FactoryBot.create(:file, context: submission)
        expect(file_accepted?(new_file)).to be true
      end
    end

    describe 'rejects' do
      it 'file of different exercise' do
        fibonacci = FactoryBot.create(:fibonacci, allow_file_creation: true)
        other_exercises_file = FactoryBot.create(:file, context: fibonacci)
        expect(file_accepted?(other_exercises_file)).to be false
      end

      it 'hidden file' do
        hidden_file = FactoryBot.create(:file, context: hello_world, hidden: true)
        expect(file_accepted?(hidden_file)).to be false
      end

      it 'read only file' do
        read_only_file = FactoryBot.create(:file, context: hello_world, read_only: true)
        expect(file_accepted?(read_only_file)).to be false
      end

      it 'non existent file' do
        non_existent_file = FactoryBot.build(:file, context: hello_world, id: 42)
        expect(file_accepted?(non_existent_file)).to be false
      end
    end
  end
end
