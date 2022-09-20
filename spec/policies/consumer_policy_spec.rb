# frozen_string_literal: true

require 'rails_helper'

describe ConsumerPolicy do
  subject(:policy) { described_class }

  %i[create? destroy? edit? index? new? show? update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(policy).to permit(build(:admin), Consumer.new)
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), Consumer.new)
        end
      end
    end
  end
end
