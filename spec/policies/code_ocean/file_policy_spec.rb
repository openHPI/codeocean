# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CodeOcean::FilePolicy do
  subject(:policy) { described_class }

  let(:exercise) { create(:fibonacci) }
  let(:submission) { create(:submission) }

  permissions :create? do
    context 'when being part of an exercise' do
      let(:file) { exercise.files.first }

      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), file)
      end

      it 'grants access to authors' do
        expect(policy).to permit(exercise.author, file)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), file)
        end
      end
    end

    context 'when being part of a submission' do
      let(:file) { submission.files.first }

      shared_context 'when file creation is allowed' do
        before do
          submission.exercise.update(allow_file_creation: true)
        end
      end

      shared_context 'when file creation is not allowed' do
        before do
          submission.exercise.update(allow_file_creation: false)
        end
      end

      shared_examples 'no other user allowed to access' do
        it 'does not grant access to all other users' do
          %i[admin external_user teacher].each do |factory_name|
            expect(policy).not_to permit(create(factory_name), file)
          end
        end
      end

      context 'when a single user authored' do
        context 'when file creation is allowed' do
          include_context 'when file creation is allowed'

          it 'grants access to authors' do
            expect(policy).to permit(submission.author, file)
          end

          it_behaves_like 'no other user allowed to access'
        end

        context 'when file creation is not allowed' do
          include_context 'when file creation is not allowed'

          it 'does not grant access to authors' do
            expect(policy).not_to permit(submission.author, file)
          end

          it_behaves_like 'no other user allowed to access'
        end
      end

      context 'when a programming group authored' do
        let(:group_author) { create(:external_user) }
        let(:other_group_author) { create(:external_user) }
        let(:programming_group) { create(:programming_group, exercise: submission.exercise, users: [group_author, other_group_author]) }

        before do
          submission.update(contributor: programming_group)
        end

        context 'when file creation is allowed' do
          include_context 'when file creation is allowed'

          it 'grants access to authors' do
            expect(policy).to permit(group_author, file)
            expect(policy).to permit(other_group_author, file)
          end

          it_behaves_like 'no other user allowed to access'
        end

        context 'when file creation is not allowed' do
          include_context 'when file creation is not allowed'

          it 'does not grant access to authors' do
            expect(policy).not_to permit(group_author, file)
            expect(policy).not_to permit(other_group_author, file)
          end

          it_behaves_like 'no other user allowed to access'
        end
      end

      it_behaves_like 'no other user allowed to access'
    end
  end

  permissions :destroy? do
    context 'when being part of an exercise' do
      let(:file) { exercise.files.first }

      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), file)
      end

      it 'grants access to authors' do
        expect(policy).to permit(exercise.author, file)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), file)
        end
      end
    end

    context 'when being part of a submission' do
      let(:file) { submission.files.first }

      it 'does not grant access to anyone' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), file)
        end
      end
    end
  end
end
