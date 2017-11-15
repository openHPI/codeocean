require 'rails_helper'

describe SubmissionPolicy do
  subject { described_class }

  permissions :create? do
    it 'grants access to anyone' do
      [:admin, :external_user, :teacher].each do |factory_name|
        expect(subject).to permit(FactoryBot.build(factory_name), Submission.new)
      end
    end
  end

  [:download_file?, :render_file?, :run?, :score?, :show?, :statistics?, :stop?, :test?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), Submission.new)
      end

      it 'grants access to authors' do
        user = FactoryBot.create(:external_user)
        expect(subject).to permit(user, FactoryBot.build(:submission, exercise: Exercise.new, user_id: user.id, user_type: user.class.name))
      end
    end
  end

  permissions :index? do
    it 'grants access to admins only' do
      expect(subject).to permit(FactoryBot.build(:admin), Submission.new)
      [:external_user, :teacher].each do |factory_name|
        expect(subject).not_to permit(FactoryBot.build(factory_name), Submission.new)
      end
    end
  end
end
