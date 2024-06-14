# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'sessions/destroy_through_lti.html.slim' do
  let(:consumer) { create(:consumer) }
  let(:submission) { create(:submission, exercise: create(:dummy)) }

  before do
    without_partial_double_verification do
      allow(view).to receive_messages(current_user: submission.contributor)
    end

    assign(:submission, submission)
    assign(:lti_parameter, lti_parameter)
    assign(:url, url)

    render
  end

  context 'when a launch return presentation URL is provided' do
    let(:url) { 'https://example.com' }

    context 'when a LIS Outcome service URL is provided' do
      let(:lti_parameter) { create(:lti_parameter, external_user: submission.contributor) }

      it 'contains the desired success message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.success_with_outcome', consumer:))
      end

      it 'contains the desired finish message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.finished_with_consumer', consumer:, url:))
      end
    end

    context 'when no LIS Outcome service URL is provided' do
      let(:lti_parameter) { create(:lti_parameter, :without_outcome_service_url, external_user: submission.contributor) }

      it 'contains the desired success message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.success_without_outcome'))
      end

      it 'contains the desired finish message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.finished_with_consumer', consumer:, url:))
      end
    end
  end

  context 'when no launch return presentation URL is provided' do
    let(:url) { nil }

    context 'when a LIS Outcome service URL is provided' do
      let(:lti_parameter) { create(:lti_parameter, :without_return_url, external_user: submission.contributor) }

      it 'contains the desired success message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.success_with_outcome', consumer:))
      end

      it 'contains the desired finish message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.finished_without_consumer'))
      end
    end

    context 'when no LIS Outcome service URL is provided' do
      let(:lti_parameter) { create(:lti_parameter, :without_return_url, :without_outcome_service_url, external_user: submission.contributor) }

      it 'contains the desired success message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.success_without_outcome'))
      end

      it 'contains the desired finish message' do
        expect(rendered).to include(I18n.t('sessions.destroy_through_lti.finished_without_consumer'))
      end
    end
  end
end
