# frozen_string_literal: true

require 'rails_helper'

describe CodeharborLinkPolicy do
  subject(:policy) { described_class }

  let(:codeharbor_link) { create(:codeharbor_link) }

  context 'when CodeHarbor link is enabled' do
    let(:codeocean_config) { instance_double(CodeOcean::Config) }
    let(:codeharbor_config) { {codeharbor: {enabled: true}} }

    before do
      allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
      allow(codeocean_config).to receive(:read).and_return(codeharbor_config)
    end

    %i[index? show?].each do |action|
      permissions(action) do
        it 'does not grant access any user' do
          %i[external_user teacher admin].each do |factory_name|
            expect(policy).not_to permit(create(factory_name), codeharbor_link)
          end
        end
      end
    end

    %i[new? create?].each do |action|
      permissions(action) do
        it 'grants access to teachers' do
          %i[teacher admin].each do |factory_name|
            expect(policy).to permit(create(factory_name), codeharbor_link)
          end
        end

        it 'does not grant access to all other users' do
          expect(policy).not_to permit(create(:external_user), codeharbor_link)
        end
      end
    end

    %i[destroy? edit? update?].each do |action|
      permissions(action) do
        it 'grants access to the owner of the link' do
          expect(policy).to permit(codeharbor_link.user, codeharbor_link)
        end

        it 'does not grant access to arbitrary users' do
          %i[external_user admin teacher].each do |factory_name|
            expect(policy).not_to permit(create(factory_name), codeharbor_link)
          end
        end
      end
    end

    permissions :enabled? do
      it 'reflects the config option' do
        %i[external_user admin teacher].each do |factory_name|
          expect(policy).to permit(create(factory_name), codeharbor_link)
        end
      end
    end
  end

  context 'when CodeHabor link is disabled' do
    let(:codeocean_config) { instance_double(CodeOcean::Config) }
    let(:codeharbor_config) { {codeharbor: {enabled: false}} }

    before do
      allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
      allow(codeocean_config).to receive(:read).and_return(codeharbor_config)
    end

    permissions :enabled? do
      it 'reflects the config option' do
        %i[external_user admin teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), codeharbor_link)
        end
      end
    end
  end
end
