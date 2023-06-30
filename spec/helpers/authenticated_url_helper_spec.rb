# frozen_string_literal: true

require 'rails_helper'

describe AuthenticatedUrlHelper do
  describe '#add_query_parameters' do
    it 'adds the given parameters to the given url' do
      expect(described_class.add_query_parameters(root_url, {foo: 'bar'})).to eq(root_url(foo: 'bar'))
    end

    it 'does not duplicate existing parameters' do
      expect(described_class.add_query_parameters(root_url(foo: 'bar'), {foo: 'baz'})).to eq(root_url(foo: 'baz'))
    end
  end
end