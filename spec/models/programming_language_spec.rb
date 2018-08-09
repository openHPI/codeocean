require 'rails_helper'

describe ProgrammingLanguage do
  let(:programming_language) { FactoryBot.create(:ruby_2_2)}

  it 'returns correct name with version' do
    expect(programming_language.name_with_version).to eq('Ruby 2.2')
  end

  it 'check default true' do
    expect(programming_language.check_default("true")).to be true
  end
end