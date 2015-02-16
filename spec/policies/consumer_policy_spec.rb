require 'rails_helper'

describe ConsumerPolicy do
  subject { described_class }

  [:create?, :destroy?, :edit?, :index?, :new?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(subject).to permit(FactoryGirl.build(:admin), Consumer.new)
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), Consumer.new)
        end
      end
    end
  end
end
