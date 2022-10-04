# frozen_string_literal: true

require 'rails_helper'

describe 'execution_environments/shell.html.slim' do
  let(:execution_environment) { create(:ruby) }

  before do
    assign(:execution_environment, execution_environment)
    render
  end

  it 'contains the required data attributes' do
    expect(rendered).to have_css('#shell[data-message-timeout]')
    expect(rendered).to have_css("#shell[data-id='#{execution_environment.id}']")
  end
end
