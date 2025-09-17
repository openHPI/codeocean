# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /comments/:comment_id/report', type: :request do
  let(:user) { create(:learner) }
  let(:comment) { create(:comment) }

  before do
    stub_const('CommentPolicy::REPORT_RECEIVER_CONFIGURED', true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  it 'sends an email to let admins know about the report' do
    expect { post(report_comment_path(comment)) }
      .to have_enqueued_mail(UserContentReportMailer, :report_content)
      .with(params: {reported_content: comment}, args: [])
  end
end
