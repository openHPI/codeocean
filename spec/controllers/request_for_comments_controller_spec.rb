require 'rails_helper'

describe RequestForCommentsController do
  let(:user) { FactoryBot.create(:admin) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe 'GET #index' do
    it 'renders the index template' do
      get :index

      expect(response).to have_http_status :ok
      expect(response).to render_template :index
    end

    it 'shows only rfc`s belonging to selected study group' do
      my_study_group = FactoryBot.create(:study_group)
      rfc_within_my_study_group = FactoryBot.create(:rfc, user: user)
      user.update(study_groups: [my_study_group])
      rfc_within_my_study_group.submission.update(study_group: my_study_group)

      another_study_group = FactoryBot.create(:study_group)
      rfc_other_study_group = FactoryBot.create(:rfc)
      rfc_other_study_group.user.update(study_groups: [another_study_group])
      rfc_other_study_group.submission.update(study_group: another_study_group)

      get :index, params: { "q[submission_study_group_id_in][]": my_study_group.id }

      expect(assigns(:request_for_comments)).to eq([rfc_within_my_study_group])
    end
  end

  describe 'GET #get_my_comment_requests' do
    before { get :get_my_comment_requests }

    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #get_rfcs_with_my_comments' do
    before { get :get_rfcs_with_my_comments }

    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #get_rfcs_for_exercise' do
    before do
      exercise = FactoryBot.create(:even_odd)
      get :get_rfcs_for_exercise, params: { exercise_id: exercise.id }
    end

    expect_status(200)
    expect_template(:index)
  end
end
