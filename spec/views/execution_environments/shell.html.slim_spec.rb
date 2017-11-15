require 'rails_helper'

describe 'execution_environments/shell.html.slim' do
  let(:execution_environment) { FactoryBot.create(:ruby) }

  before(:each) do
    assign(:execution_environment, execution_environment)
    render
  end

  it 'contains the required data attributes' do
    expect(rendered).to have_css('#shell[data-message-timeout]')
    expect(rendered).to have_css("#shell[data-url='#{execute_command_execution_environment_path(execution_environment)}']")
  end
end
