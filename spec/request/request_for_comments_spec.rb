# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /request_for_comments/:rfc_id/report', type: :request do
  it 'sends an email to let admins know about the report' do
    user = create(:learner)
    password = attributes_for(:learner).fetch(:password)
    login_as(user, password)
    rfc = create(:rfc)

    expect { post(report_request_for_comment_path(rfc, session: {foo: 'bar'})) }
      .to have_enqueued_mail(ReportMailer, :report_content)
      .with(params: {reported_content: rfc}, args: [])
  end
end
