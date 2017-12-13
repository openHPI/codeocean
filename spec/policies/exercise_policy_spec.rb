require 'rails_helper'

describe ExercisePolicy do
  subject { described_class }

let(:exercise) { FactoryBot.build(:dummy) }
  
  permissions :batch_update? do
    it 'grants access to admins only' do
      expect(subject).to permit(FactoryBot.build(:admin), exercise)
      [:external_user, :teacher].each do |factory_name|
        expect(subject).not_to permit(FactoryBot.build(factory_name), exercise)
      end
    end
  end

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), exercise)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryBot.build(:teacher), exercise)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), exercise)
      end
    end
  end

  [:clone?, :destroy?, :edit?, :statistics?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), exercise)
      end

      it 'grants access to authors' do
        expect(subject).to permit(exercise.author, exercise)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), exercise)
        end
      end
    end
  end

  [:show?].each do |action|
    permissions(action) do
      it 'not grants access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), exercise)
      end
    end
  end

  [:implement?, :submit?].each do |action|
    permissions(action) do
      it 'grants access to anyone' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).to permit(FactoryBot.build(factory_name), Exercise.new)
        end
      end
    end
  end

  describe ExercisePolicy::Scope do
    describe '#resolve' do
      before(:all) do
        @admin = FactoryBot.create(:admin)
        @external_user = FactoryBot.create(:external_user)
        @teacher = FactoryBot.create(:teacher)

        [@admin, @teacher].each do |user|
          [true, false].each do |public|
            FactoryBot.create(:dummy, public: public, user_id: user.id, user_type: InternalUser.class.name)
          end
        end
      end

      context 'for admins' do
        let(:scope) { Pundit.policy_scope!(@admin, Exercise) }

        it 'returns all exercises' do
          expect(scope.map(&:id)).to include(*Exercise.all.map(&:id))
        end
      end

      context 'for external users' do
        let(:scope) { Pundit.policy_scope!(@external_user, Exercise) }

        it 'returns nothing' do
          expect(scope.count).to be 0
        end
      end

      context 'for teachers' do

        let(:scope) { Pundit.policy_scope!(@teacher, Exercise) }

        it 'includes all public exercises' do
          expect(scope.map(&:id)).to include(*Exercise.where(public: true).map(&:id))
        end

        it 'includes all authored non-public exercises' do
          expect(scope.map(&:id)).to include(*Exercise.where(public: false, user_id: @teacher.id).map(&:id))
        end

        it "does not include other authors' non-public exercises" do
          expect(scope.map(&:id)).not_to include(*Exercise.where(public: false).where("user_id <> #{@teacher.id}").map(&:id))
        end
      end
    end
  end
end
