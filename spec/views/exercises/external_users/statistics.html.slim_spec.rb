# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'exercises/external_users/statistics.html.slim' do
  let(:user) { create(:admin) }
  let(:exercise) { create(:fibonacci, user:) }
  let(:external_user) { create(:external_user) }

  before do
    create_list(:submission, 2, cause: 'autosave', contributor: external_user, exercise:)
    create_list(:submission, 2, cause: 'run', contributor: external_user, exercise:)
    create(:submission, cause: 'assess', contributor: external_user, exercise:)

    without_partial_double_verification do
      allow(view).to receive_messages(current_user: user, current_contributor: user)
    end
    assign(:exercise, exercise)
    assign(:show_autosaves, false)
    assign(:external_user, external_user)
    assign(:all_events, external_user.submissions.where(exercise:))

    # The following two variables normally contain the time between two submissions (delta)
    # if lower than StatisticsHelper::WORKING_TIME_DELTA_IN_SECONDS, and the sum of all deltas.
    # For the spec, we simply assume no working time and therefore fill both arrays with zeros.
    assign(:deltas, [0] * external_user.submissions.where(exercise:).count)
    assign(:working_times_until, [0] * external_user.submissions.where(exercise:).count)

    # Manipulate the controller instance to include necessary path options
    controller.request.path_parameters[:id] = exercise.id
    controller.request.path_parameters[:external_user_id] = external_user.id

    render
  end

  it 'displays the correct title' do
    parsed_content = Nokogiri::HTML(rendered)
    text_content = parsed_content.text.strip
    expect(text_content).to include("#{exercise} (#{ExternalUser.model_name.human} #{external_user.displayname})")
  end

  it 'contains a link to the user' do
    expect(rendered).to have_link(external_user.displayname, href: external_user_path(external_user))
  end
end
