# frozen_string_literal: true

require 'rails_helper'

describe ProgrammingGroupPolicy do
  subject(:policy) { described_class }

  let(:programming_group) { build(:programming_group) }

  %i[new? create?].each do |action|
    permissions(action) do
      it 'grants access to everyone' do
        %i[external_user teacher admin].each do |factory_name|
          expect(policy).to permit(create(factory_name), programming_group)
        end
      end
    end
  end
end
