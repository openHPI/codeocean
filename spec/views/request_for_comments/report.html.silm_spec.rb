# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'request_for_comments/report.html.slim' do
  let(:rfc) { build_stubbed(:rfc) }

  before do
    assign(:current_user, build_stubbed(:external_user))
    allow(view).to receive(:policy).with(rfc).and_return(report_policy)
    render('request_for_comments/report', request_for_comment: rfc)
  end

  context 'when reporting is allowed' do
    let(:report_policy) { instance_double(RequestForCommentPolicy, report?: true) }

    it 'displays the report button when the request is authorized' do
      expect(rendered).to have_button
    end
  end

  context 'when reporting is prohibbeted' do
    let(:report_policy) { instance_double(RequestForCommentPolicy, report?: false) }

    it 'dose not display report button when reporting is not authorized' do
      expect(rendered).to have_no_button
    end
  end
end
