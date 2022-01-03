# frozen_string_literal: true

require 'rails_helper'

describe CodeharborLink do
  it { is_expected.to validate_presence_of(:check_uuid_url) }
  it { is_expected.to validate_presence_of(:push_url) }
  it { is_expected.to validate_presence_of(:api_key) }
  it { is_expected.to belong_to(:user) }

  describe '#to_s' do
    subject { codeharbor_link.to_s }

    let(:codeharbor_link) { create(:codeharbor_link) }

    it { is_expected.to eql codeharbor_link.id.to_s }
  end
end
