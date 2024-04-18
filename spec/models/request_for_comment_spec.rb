# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestForComment do
  describe 'scope with_comments' do
    let!(:rfc) { create(:rfc) }
    let!(:rfc2) { create(:rfc_with_comment) }

    it 'includes all RfCs with comments' do
      expect(described_class.with_comments).to include(rfc2)
    end

    it 'does not include any RfC without a comment' do
      expect(described_class.with_comments).not_to include(rfc)
    end
  end

  describe 'state' do
    let!(:rfc_solved) { create(:rfc, solved: true) }
    let!(:rfc_soft_solved) { create(:rfc, solved: false, full_score_reached: true) }
    let!(:rfc_ongoing) { create(:rfc, solved: false, full_score_reached: false) }

    it 'returns solved RfCs when solved state is requested' do
      expect(described_class.state(RequestForComment::SOLVED)).to contain_exactly(rfc_solved)
    end

    it 'returns soft solved RfCs when soft solved state is requested' do
      expect(described_class.state(RequestForComment::SOFT_SOLVED)).to contain_exactly(rfc_soft_solved)
    end

    it 'returns ongoing RfCs when ongoing state is requested' do
      expect(described_class.state(RequestForComment::ONGOING)).to contain_exactly(rfc_ongoing)
    end

    it 'returns all RfCs when all state is requested' do
      expect(described_class.state(RequestForComment::ALL)).to contain_exactly(rfc_solved, rfc_soft_solved, rfc_ongoing)
    end
  end
end
