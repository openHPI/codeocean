# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProgrammingGroupsController do
  render_views

  let(:user) { create(:admin) }
  let(:other_user) { create(:external_user) }
  let(:exercise) { create(:math) }
  let(:exercise_id) { exercise.id }
  let(:programming_group) { create(:programming_group, exercise:, users: [user, other_user]) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    let(:user_to_params) { ->(users) { users.map(&:id_with_type).join(', ') } }
    let(:perform_request) { proc { post :create, params: {exercise_id:, programming_group: pg_params} } }

    context 'with a valid programming group' do
      let(:pg_params) { {programming_partner_ids: user_to_params.call([other_user])} }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
        expect_redirect(ProgrammingGroup.last)
      end

      it 'creates the programming group' do
        expect { perform_request.call }.to change(ProgrammingGroup, :count).by(1).and change(ProgrammingGroupMembership, :count).by(2)
      end

      it 'does not create a new event' do
        expect { perform_request.call }.not_to change(Event, :count)
      end

      it 'updates the status of the initiating waiting user' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user:, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.to change(pp_waiting_user, :status).from('waiting').to('created_pg')
      end

      it 'updates the status of other waiting users' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user: other_user, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.to change(pp_waiting_user, :status).from('waiting').to('invited_to_pg')
      end

      it 'stores the programming group ID in the session' do
        allow(controller.session).to receive(:[]=).and_call_original
        perform_request.call
        expect(controller.session).to have_received(:[]=).with(:pg_id, ProgrammingGroup.last.id)
      end
    end

    context 'with an invalid programming group' do
      let(:pg_params) { {} }

      before { post :create, params: {exercise_id:, programming_group: pg_params} }

      expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
      expect_http_status(:ok)
      expect_template(:new)

      it 'does not create a new programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'creates a new event' do
        expect { perform_request.call }.to change(Event, :count).by(1)
      end

      it 'does not update the status of the initiating waiting user' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user:, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.not_to change(pp_waiting_user, :status)
      end

      it 'does not update the status of other waiting users' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user: other_user, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.not_to change(pp_waiting_user, :status)
      end
    end

    context 'with a duplicated membership' do
      let(:pg_params) { {programming_partner_ids: user_to_params.call(programming_group.users)} }

      before { programming_group.save! }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
        expect_http_status(:ok)
        expect_template(:new)
      end

      it 'does not create a new programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'creates a new event' do
        expect { perform_request.call }.to change(Event, :count).by(1)
      end

      it 'does not update the status of the initiating waiting user' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user:, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.not_to change(pp_waiting_user, :status)
      end

      it 'does not update the status of other waiting users' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user: other_user, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.not_to change(pp_waiting_user, :status)
      end
    end

    context 'with a user providing their own ID' do
      let(:pg_params) { {programming_partner_ids: user_to_params.call([user, other_user])} }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
        expect_redirect(ProgrammingGroup.last)
      end

      it 'creates a new programming group' do
        expect { perform_request.call }.to change(ProgrammingGroup, :count).by(1).and change(ProgrammingGroupMembership, :count).by(2)
      end

      it 'does not create a new event' do
        expect { perform_request.call }.not_to change(Event, :count)
      end

      it 'updates the status of the initiating waiting user' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user:, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.to change(pp_waiting_user, :status).from('waiting').to('created_pg')
      end

      it 'updates the status of other waiting users' do
        pp_waiting_user = PairProgrammingWaitingUser.create(user: other_user, exercise:, status: :waiting)
        expect { perform_request.call && pp_waiting_user.reload }.to change(pp_waiting_user, :status).from('waiting').to('invited_to_pg')
      end

      it 'stores the programming group ID in the session' do
        allow(controller.session).to receive(:[]=).and_call_original
        perform_request.call
        expect(controller.session).to have_received(:[]=).with(:pg_id, ProgrammingGroup.last.id)
      end
    end

    context 'with invalid programming partner IDs' do
      let(:pg_params) { {programming_partner_ids: 'test1234'} }

      before { post :create, params: {exercise_id:, programming_group: pg_params} }

      expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
      expect_http_status(:ok)
      expect_template(:new)

      it 'does not create a new programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'creates a new event' do
        expect { perform_request.call }.to change(Event, :count).by(1)
      end
    end

    context 'with too many users' do
      let(:third_user) { create(:external_user) }
      let(:pg_params) { {programming_partner_ids: user_to_params.call([other_user, third_user])} }

      before { post :create, params: {exercise_id:, programming_group: pg_params} }

      expect_assigns(exercise: :exercise, programming_group: ProgrammingGroup)
      expect_http_status(:ok)
      expect_template(:new)

      it 'does not create a new programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'creates a new event' do
        expect { perform_request.call }.to change(Event, :count).by(1)
      end
    end
  end

  describe 'DELETE #destroy' do
    before { delete :destroy, params: {id: programming_group.id} }

    expect_assigns(programming_group: ProgrammingGroup)

    it 'destroys the programming group' do
      programming_group = create(:programming_group)
      expect { delete :destroy, params: {id: programming_group.id} }.to change(ProgrammingGroup, :count).by(-1)
    end

    it 'removes the programming group ID from the session' do
      # Setup: Construct a programming group and set it as the current group in the session.
      programming_group = create(:programming_group, users: [user, other_user])
      allow(controller.session).to receive(:[]).and_call_original
      allow(controller.session).to receive(:[]).with(:pg_id).and_return programming_group.id

      # Test: Destroy the programming group and verify that it is no longer retained in the session.
      allow(controller.session).to receive(:delete).and_call_original
      delete :destroy, params: {id: programming_group.id}
      expect(controller.session).to have_received(:delete).with(:pg_id)
    end

    expect_redirect(:programming_groups)
  end

  describe 'GET #edit' do
    before { get :edit, params: {id: programming_group.id} }

    expect_assigns(programming_group: ProgrammingGroup)
    expect_http_status(:ok)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before do
      create_pair(:programming_group)
      get :index
    end

    expect_assigns(programming_groups: ProgrammingGroup.all)
    expect_http_status(:ok)
    expect_template(:index)
  end

  describe 'GET #new' do
    let(:perform_request) { proc { get :new, params: {exercise_id:} } }

    context 'when the request is performed' do
      before { perform_request.call }

      expect_assigns(programming_group: ProgrammingGroup)
      expect_http_status(:ok)
      expect_template(:new)
    end

    it 'creates a new event' do
      expect { perform_request.call }.to change(Event, :count).by(1)
    end

    context 'with an existing programming group' do
      let(:programming_group) { create(:programming_group, exercise:, users: [user, other_user]) }

      before { programming_group.save! }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_redirect { implement_exercise_path(exercise) }

        it 'stores the programming group ID in the session' do
          allow(controller.session).to receive(:[]=).and_call_original
          perform_request.call
          expect(controller.session).to have_received(:[]=).with(:pg_id, programming_group.id)
        end
      end

      context 'when the user has already started the exercise' do
        before { create(:submission, exercise:, user:) }

        context 'when the request is performed' do
          before { perform_request.call }

          expect_redirect { implement_exercise_path(exercise) }

          it 'does not store the programming group ID in the session' do
            allow(controller.session).to receive(:[]=).and_call_original
            perform_request.call
            expect(controller.session).not_to have_received(:[]=).with(:pg_id)
          end
        end
      end
    end
  end

  describe 'GET #show' do
    before { get :show, params: {id: programming_group.id} }

    expect_assigns(programming_group: :programming_group)
    expect_http_status(:ok)
    expect_template(:show)
  end

  describe 'PUT #update' do
    let(:perform_request) { proc { put :update, params: {programming_group: pg_params, id: programming_group.id} } }

    before do
      # In order to test a successful update, we need to remove a user from the programming group.
      # Since otherwise the group size is fixed to exactly two members, we temporarily allow a larger group size.
      allow_any_instance_of(ProgrammingGroup).to receive(:max_group_size).and_return(true)
      # The programming group needs to be saved, otherwise we cannot attempt to update it.
      programming_group.save!
    end

    context 'with a valid programming group' do
      let(:programming_group) { create(:programming_group, exercise:, users: create_list(:external_user, 3)) }
      let(:pg_params) { {programming_group_membership_ids: programming_group.programming_group_memberships.map(&:id)[0..1]} }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(programming_group: ProgrammingGroup)
        expect_redirect(:programming_group)
      end

      it 'does not update the programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'removes the desired programming group membership' do
        expect { perform_request.call }.to change(ProgrammingGroupMembership, :count).by(-1)
      end

      it 'does not update any existing programming group membership' do
        expect { perform_request.call && programming_group.programming_group_memberships.first.reload }.not_to change(programming_group.programming_group_memberships.first, :updated_at)
      end
    end

    context 'with an invalid programming group' do
      let(:pg_params) { {programming_group_membership_ids: []} }

      context 'when the request is performed' do
        before { perform_request.call }

        expect_assigns(programming_group: ProgrammingGroup)
        expect_http_status(:ok)
        expect_template(:edit)
      end

      it 'does not update the programming group' do
        expect { perform_request.call }.not_to change(ProgrammingGroup, :count)
      end

      it 'does not update the programming group memberships' do
        expect { perform_request.call }.not_to change(ProgrammingGroupMembership, :count)
      end
    end
  end
end
