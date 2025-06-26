# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /request_for_comments/:rfc_id/report', type: :request do
  let(:user) { create(:learner) }
  let(:rfc) { create(:rfc) }

  before do
    stub_const('RequestForCommentPolicy::REPORT_RECEIVER_CONFIGURED', true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  it 'sends an email to let admins know about the report' do
    expect { post(report_request_for_comment_path(rfc)) }
      .to have_enqueued_mail(ReportMailer, :report_content)
      .with(params: {reported_content: rfc}, args: [])
  end
end
