# frozen_string_literal: true

require 'rails_helper'

describe FileTypePolicy do
  subject(:policy) { described_class }

  let(:file_type) { build(:dot_rb) }

  %i[destroy? edit? update? new? create? index? show?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), file_type)
      end

      it 'grants access to authors' do
        expect(policy).to permit(file_type.author, file_type)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), file_type)
        end
      end
    end
  end
end
