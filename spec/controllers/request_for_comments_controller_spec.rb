# frozen_string_literal: true

require 'rails_helper'

describe RequestForCommentsController do
  render_views

  let(:user) { create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  shared_examples 'RfC visibility settings' do
    let(:user) { create(:learner) }

    let!(:rfc_other_consumer) do
      rfc = create(:rfc)
      rfc.user.update(consumer: create(:consumer, name: 'Other Consumer'))
      rfc
    end

    let!(:rfc_other_study_group) do
      rfc = create(:rfc)
      rfc.user.update(consumer: user.consumer)
      rfc.submission.update(study_group: create(:study_group))
      rfc
    end

    let!(:rfc_peer) do
      rfc = create(:rfc)
      rfc.user.update(consumer: user.consumer)
      rfc.submission.update(study_group: user.study_groups.first)
      rfc
    end

    context 'when rfc_visibility is set to all' do
      before { user.consumer.update(rfc_visibility: 'all') }

      it 'shows all RfCs' do
        get :index
        expect(assigns(:request_for_comments)).to contain_exactly(rfc_other_consumer, rfc_other_study_group, rfc_peer)
      end
    end

    context 'when rfc_visibility is set to consumer' do
      before { user.consumer.update(rfc_visibility: 'consumer') }

      it 'shows only RfCs of the same consumer' do
        get :index
        expect(assigns(:request_for_comments)).to contain_exactly(rfc_other_study_group, rfc_peer)
      end
    end

    context 'when rfc_visibility is set to study_group' do
      before { user.consumer.update(rfc_visibility: 'study_group') }

      it 'shows only RfCs of the same study group' do
        get :index
        expect(assigns(:request_for_comments)).to contain_exactly(rfc_peer)
      end
    end
  end

  describe 'GET #index' do
    it 'renders the index template' do
      get :index

      expect(response).to have_http_status :ok
      expect(response).to render_template :index
    end

    it 'shows only rfc`s belonging to selected study group' do
      my_study_group = create(:study_group)
      rfc_within_my_study_group = create(:rfc, user:)
      user.update(study_groups: [my_study_group])
      rfc_within_my_study_group.submission.update(study_group: my_study_group)

      another_study_group = create(:study_group)
      rfc_other_study_group = create(:rfc)
      rfc_other_study_group.user.update(study_groups: [another_study_group])
      rfc_other_study_group.submission.update(study_group: another_study_group)

      get :index, params: {'q[submission_study_group_id_in][]': my_study_group.id}

      expect(assigns(:request_for_comments)).to eq([rfc_within_my_study_group])
    end

    include_examples 'RfC visibility settings'
  end

  describe 'GET #my_comment_requests' do
    before { get :my_comment_requests }

    expect_http_status(:ok)
    expect_template(:index)

    include_examples 'RfC visibility settings'
  end

  describe 'GET #rfcs_with_my_comments' do
    before { get :rfcs_with_my_comments }

    expect_http_status(:ok)
    expect_template(:index)

    include_examples 'RfC visibility settings'
  end

  describe 'GET #rfcs_for_exercise' do
    before do
      exercise = create(:even_odd)
      get :rfcs_for_exercise, params: {exercise_id: exercise.id}
    end

    expect_http_status(:ok)
    expect_template(:index)
  end
end
