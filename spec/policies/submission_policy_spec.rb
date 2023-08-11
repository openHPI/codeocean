# frozen_string_literal: true

require 'rails_helper'

describe SubmissionPolicy do
  subject(:policy) { described_class }

  permissions :create? do
    it 'grants access to anyone' do
      %i[admin external_user teacher].each do |factory_name|
        expect(policy).to permit(create(factory_name), Submission.new)
      end
    end
  end

  %i[download_file? render_file? run? score? show? statistics? stop? test?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), Submission.new)
      end

      it 'grants access to authors' do
        contributor = create(:external_user)
        expect(policy).to permit(contributor, build(:submission, exercise: Exercise.new, contributor:))
      end
    end
  end

  permissions :index? do
    it 'grants access to admins only' do
      expect(policy).to permit(build(:admin), Submission.new)
      %i[external_user teacher].each do |factory_name|
        expect(policy).not_to permit(create(factory_name), Submission.new)
      end
    end
  end
end
