# frozen_string_literal: true

require 'rails_helper'

describe CodeOcean::FilePolicy do
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

      context 'when file creation is allowed' do
        before do
          submission.exercise.update(allow_file_creation: true)
        end

        it 'grants access to authors' do
          expect(policy).to permit(submission.author, file)
        end
      end

      context 'when file creation is not allowed' do
        before do
          submission.exercise.update(allow_file_creation: false)
        end

        it 'grants access to authors' do
          expect(policy).not_to permit(submission.author, file)
        end
      end

      it 'does not grant access to all other users' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), file)
        end
      end
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
