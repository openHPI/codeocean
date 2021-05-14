# frozen_string_literal: true

require 'rails_helper'

describe ApplicationPolicy do
  describe '#initialize' do
    context 'without a user' do
      it 'raises an error' do
        expect { described_class.new(nil, nil) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
