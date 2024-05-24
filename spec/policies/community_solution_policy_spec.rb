# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommunitySolutionPolicy do
  subject(:policy) { described_class }

  permissions(:index?) do
    it 'grants access to admins only' do
      expect(policy).to permit(build(:admin), Consumer.new)
      %i[external_user teacher].each do |factory_name|
        expect(policy).not_to permit(create(factory_name), Consumer.new)
      end
    end
  end

  %i[edit? update?].each do |action|
    permissions(action) do
      it 'grants access to anyone' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).to permit(create(factory_name), CommunitySolution.new)
        end
      end
    end
  end

  %i[create? destroy? new? show?].each do |action|
    permissions(action) do
      it 'does not grant access to anyone' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), CommunitySolution.new)
        end
      end
    end
  end
end
