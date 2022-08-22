# frozen_string_literal: true

require 'rails_helper'

describe ExercisePolicy do
  subject(:policy) { described_class }

  let(:exercise) { build(:dummy, public: true) }

  permissions :batch_update? do
    it 'grants access to admins only' do
      expect(policy).to permit(build(:admin), exercise)
      %i[external_user teacher].each do |factory_name|
        expect(policy).not_to permit(build(factory_name), exercise)
      end
    end
  end

  %i[create? index? new? statistics? feedback? rfcs_for_exercise?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), exercise)
      end

      it 'grants access to teachers' do
        expect(policy).to permit(build(:teacher), exercise)
      end

      it 'does not grant access to external users' do
        expect(policy).not_to permit(build(:external_user), exercise)
      end
    end
  end

  %i[clone? destroy? edit? update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), exercise)
      end

      it 'grants access to authors' do
        expect(policy).to permit(exercise.author, exercise)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(build(factory_name), exercise)
        end
      end
    end
  end

  %i[export_external_check? export_external_confirm?].each do |action|
    permissions(action) do
      context 'when user is author' do
        let(:user) { exercise.author }

        it 'does not grant access' do
          expect(policy).not_to permit(user, exercise)
        end

        context 'when user has codeharbor_link' do
          before { user.codeharbor_link = build(:codeharbor_link) }

          it 'grants access' do
            expect(policy).to permit(user, exercise)
          end
        end
      end

      context 'when user is admin' do
        let(:user) { build(:admin) }

        it 'does not grant access' do
          expect(policy).not_to permit(user, exercise)
        end

        context 'when user has codeharbor_link' do
          before { user.codeharbor_link = build(:codeharbor_link) }

          it 'grants access' do
            expect(policy).to permit(user, exercise)
          end
        end
      end

      %i[external_user teacher].each do |factory_name|
        context "when user is #{factory_name}" do
          let(:user) { build(factory_name) }

          it 'does not grant access' do
            expect(policy).not_to permit(user, exercise)
          end

          context 'when user has codeharbor_link' do
            before { user.codeharbor_link = build(:codeharbor_link) }

            it 'does not grant access' do
              expect(policy).not_to permit(user, exercise)
            end
          end
        end
      end
    end
  end

  [:show?].each do |action|
    permissions(action) do
      it 'not grants access to external users' do
        expect(policy).not_to permit(build(:external_user), exercise)
      end
    end
  end

  %i[implement?].each do |action|
    permissions(action) do
      it 'grants access to anyone' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).to permit(build(factory_name), Exercise.new)
        end
      end
    end
  end

  %i[submit?].each do |action|
    permissions(action) do
      context 'when teacher-defined assessments are available' do
        before { create(:test_file, context: exercise) }

        it 'grants access to anyone' do
          %i[admin external_user teacher].each do |factory_name|
            expect(policy).to permit(build(factory_name), exercise)
          end
        end
      end

      context 'when teacher-defined assessments are not available' do
        it 'does not grant access to anyone' do
          %i[admin external_user teacher].each do |factory_name|
            expect(policy).not_to permit(build(factory_name), exercise)
          end
        end
      end
    end
  end

  describe ExercisePolicy::Scope do
    describe '#resolve' do
      let(:admin) { create(:admin) }
      let(:external_user) { create(:external_user) }
      let(:teacher) { create(:teacher) }

      before do
        [admin, teacher].each do |user|
          [true, false].each do |public|
            create(:dummy, public: public, user_id: user.id, user_type: InternalUser.name)
          end
        end
      end

      context 'when being an admin' do
        let(:scope) { Pundit.policy_scope!(admin, Exercise) }

        it 'returns all exercises' do
          expect(scope.map(&:id)).to include(*Exercise.all.map(&:id))
        end
      end

      context 'when being an external users' do
        let(:scope) { Pundit.policy_scope!(external_user, Exercise) }

        it 'returns nothing' do
          expect(scope.count).to be 0
        end
      end

      context 'when being a teacher' do
        let(:scope) { Pundit.policy_scope!(teacher, Exercise) }

        it 'includes all public exercises' do
          expect(scope.map(&:id)).to include(*Exercise.where(public: true).map(&:id))
        end

        it 'includes all authored non-public exercises' do
          expect(scope.map(&:id)).to include(*Exercise.where(public: false, user_id: teacher.id).map(&:id))
        end

        it "does not include other authors' non-public exercises" do
          expect(scope.map(&:id)).not_to include(*Exercise.where(public: false).where("user_id <> #{teacher.id}").map(&:id))
        end
      end
    end
  end
end
