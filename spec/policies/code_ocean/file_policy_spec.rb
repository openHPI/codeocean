require 'rails_helper'

describe CodeOcean::FilePolicy do
  subject { described_class }

  let(:exercise) { FactoryBot.create(:fibonacci) }
  let(:submission) { FactoryBot.create(:submission) }

  permissions :create? do
    context 'as part of an exercise' do
      let(:file) { exercise.files.first }

      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), file)
      end

      it 'grants access to authors' do
        expect(subject).to permit(exercise.author, file)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), file)
        end
      end
    end

    context 'as part of a submission' do
      let(:file) { submission.files.first }

      it 'grants access to authors' do
        expect(subject).to permit(submission.author, file)
      end

      it 'does not grant access to all other users' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), file)
        end
      end
    end
  end

  permissions :destroy? do
    context 'as part of an exercise' do
      let(:file) { exercise.files.first }

      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), file)
      end

      it 'grants access to authors' do
        expect(subject).to permit(exercise.author, file)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), file)
        end
      end
    end

    context 'as part of a submission' do
      let(:file) { submission.files.first }

      it 'does not grant access to anyone' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), file)
        end
      end
    end
  end
end
