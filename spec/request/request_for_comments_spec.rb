# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /request_for_comments/:rfc_id/report', type: :request do
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    codeocean_config = instance_double(CodeOcean::Config)
    allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
    allow(codeocean_config).to receive(:read).and_return({
      content_moderation: {report_emails: ['report@example.com']},
    })
  end

  it 'sends an email to let admins know about the report' do
    rfc = create(:rfc)

    expect { post(report_request_for_comment_path(rfc)) }
      .to have_enqueued_mail(ReportMailer, :report_content)
      .with(params: {reported_content: rfc}, args: [])
  end
end
