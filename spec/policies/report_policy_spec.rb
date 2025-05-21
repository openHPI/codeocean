# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportPolicy do
  subject(:policy) { described_class }

  permissions(:show?) do
    it 'grants access to anyone' do
      %i[admin external_user teacher].each do |factory_name|
        expect(policy).to permit(create(factory_name), Comment.new)
      end
    end

    it 'dose not allow reports when no report email is configured' do
      user = build_stubbed(:external_user)

      allow(ReportMailer).to receive(:default_params).and_return(ReportMailer.default_params.merge(to: []))

      expect(policy).not_to permit(user, Comment.new)
    end
  end

  permissions(:create?) do
    it 'grants access to anyone' do
      %i[admin external_user teacher].each do |factory_name|
        expect(policy).to permit(create(factory_name), Comment.new)
      end
    end

    it 'dose not allow reports when no report email is configured' do
      user = build_stubbed(:external_user)

      allow(ReportMailer).to receive(:default_params).and_return(ReportMailer.default_params.merge(to: []))

      expect(policy).not_to permit(user, Comment.new)
    end

    it 'allows reports on RfCs and Comments' do
      user = build_stubbed(:external_user)

      expect(policy).to permit(user, Comment.new)
      expect(policy).to permit(user, RequestForComment.new)
      expect(policy).not_to permit(user, ExternalUser.new)
    end
  end
end
