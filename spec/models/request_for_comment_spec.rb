# frozen_string_literal: true

require 'rails_helper'

describe RequestForComment do
  let!(:rfc) { create(:rfc) }

  describe 'scope with_comments' do
    let!(:rfc2) { create(:rfc_with_comment) }

    it 'includes all RfCs with comments' do
      expect(described_class.with_comments).to include(rfc2)
    end

    it 'does not include any RfC without a comment' do
      expect(described_class.with_comments).not_to include(rfc)
    end
  end
end
