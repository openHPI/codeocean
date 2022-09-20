# frozen_string_literal: true

require 'rails_helper'

describe Consumer do
  let(:consumer) { described_class.create }
  let(:valid_consumer) { create(:consumer) }

  it 'validates the presence of a name' do
    expect(consumer.errors[:name]).to be_present
  end

  it 'validates the presence of an OAuth key' do
    expect(consumer.errors[:oauth_key]).to be_present
  end

  it 'validates the uniqueness of the OAuth key' do
    consumer.update(oauth_key: create(:consumer).oauth_key)
    expect(consumer.errors[:oauth_key]).to be_present
  end

  it 'validates the presence of an OAuth secret' do
    expect(consumer.errors[:oauth_secret]).to be_present
  end

  it 'creates a study group after creation' do
    expect(valid_consumer.study_groups.count).to eq 1
  end
end
