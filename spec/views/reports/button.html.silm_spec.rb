# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reports/button.html.slim' do
  before do
    assign(:current_user, build_stubbed(:external_user))
  end

  it 'displayes the report button when the request is authorized' do
    report_policy = instance_double(ReportPolicy, show?: true)
    allow(view).to receive(:policy).with(:report).and_return(report_policy)

    render('reports/button', reported_content: build_stubbed(:comment))

    expect(rendered).to have_button
  end

  it 'has not report button when reporting is not authorized' do
    report_policy = instance_double(ReportPolicy, show?: false)
    allow(view).to receive(:policy).with(:report).and_return(report_policy)

    render('reports/button', reported_content: build_stubbed(:comment))

    expect(rendered).to have_no_button
  end
end
