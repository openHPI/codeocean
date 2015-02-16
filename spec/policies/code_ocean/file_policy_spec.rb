require 'rails_helper'

describe CodeOcean::FilePolicy do
  subject { described_class }

  permissions :create? do
    context 'as part of an exercise' do
      before(:all) do
        @exercise = FactoryGirl.create(:fibonacci)
        @file = @exercise.files.first
      end

      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), @file)
      end

      it 'grants access to authors' do
        expect(subject).to permit(@exercise.author, @file)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), @file)
        end
      end
    end

    context 'as part of a submission' do
      before(:all) do
        @submission = FactoryGirl.create(:submission)
        @file = @submission.files.first
      end

      it 'grants access to authors' do
        expect(subject).to permit(@submission.author, @file)
      end

      it 'does not grant access to all other users' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), @file)
        end
      end
    end
  end

  permissions :destroy? do
    context 'as part of an exercise' do
      before(:all) do
        @exercise = FactoryGirl.create(:fibonacci)
        @file = @exercise.files.first
      end

      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), @file)
      end

      it 'grants access to authors' do
        expect(subject).to permit(@exercise.author, @file)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), @file)
        end
      end
    end

    context 'as part of a submission' do
      before(:all) do
        @file = FactoryGirl.create(:submission).files.first
      end

      it 'does not grant access to anyone' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), @file)
        end
      end
    end
  end
end
