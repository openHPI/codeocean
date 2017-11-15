require 'rails_helper'

describe ExerciseHelper do
  describe '#embedding_parameters' do
    let(:exercise) { FactoryBot.build(:dummy) }

    it 'contains the locale' do
      expect(embedding_parameters(exercise)).to start_with("locale=#{I18n.locale}")
    end

    it 'contains the token' do
      expect(embedding_parameters(exercise)).to end_with("token=#{exercise.token}")
    end
  end
end
