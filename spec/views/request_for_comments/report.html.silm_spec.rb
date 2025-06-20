# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'request_for_comments/report.html.slim' do
  let(:rfc) { build_stubbed(:rfc) }

  before do
    assign(:current_user, build_stubbed(:external_user))
  end

  it 'displayes the report button when the request is authorized' do
    report_policy = instance_double(RequestForCommentPolicy, report?: true)
    allow(view).to receive(:policy).with(rfc).and_return(report_policy)

    render('request_for_comments/report', request_for_comment: rfc)

    expect(rendered).to have_button
  end

  it 'has no report button when reporting is not authorized' do
    report_policy = instance_double(RequestForCommentPolicy, report?: false)
    allow(view).to receive(:policy).with(rfc).and_return(report_policy)

    render('request_for_comments/report', request_for_comment: rfc)

    expect(rendered).to have_no_button
  end
end
