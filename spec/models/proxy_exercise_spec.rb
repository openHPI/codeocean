# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProxyExercise do
  describe 'defaults and validations' do
    let(:pe) { described_class.new }

    it 'sets public to false by default (after_initialize)' do
      expect(pe.public).to be(false)
    end

    it 'generates a token if none is present (after_initialize)' do
      expect(pe.token).to be_present
      expect(pe.token).to be_a(String)
      expect(pe.token.size).to eq(8) # SecureRandom.hex(4)
    end

    context 'with a token' do
      let(:pe) { build(:proxy_exercise, token: 'fixedtoken') }

      it 'does not overwrite an existing token' do
        expect(pe.token).to eq('fixedtoken')
      end
    end
  end

  describe '#count_files' do
    let(:pe) { create(:proxy_exercise, exercises: create_list(:dummy, 7)) }

    it 'returns the number of associated exercises' do
      expect(pe.count_files).to eq(7)
    end
  end

  describe '#duplicate' do
    subject(:copy) { original.duplicate(title: 'Copy') }

    let(:original) { create(:proxy_exercise, title: 'Original', token: 'tok12345') }

    it 'returns a duplicated instance with overridden attributes' do
      expect(copy).to be_a(described_class)
      expect(copy).not_to be_persisted
      expect(copy.title).to eq('Copy')
      expect(copy.token).to eq('tok12345')
    end
  end

  describe '#get_matching_exercise' do
    let(:user) { create(:learner) }

    context 'when an assignment already exists for the user' do
      subject(:get_matching_exercise) { pe.get_matching_exercise(user) }

      let(:pe) { create(:proxy_exercise) }
      let(:ex) { create(:dummy) }

      before { UserProxyExerciseExercise.create!(user:, exercise: ex, proxy_exercise: pe) }

      it { is_expected.to eql ex }

      it 'returns the previously assigned exercise without creating another one' do
        expect { get_matching_exercise }.not_to change(UserProxyExerciseExercise, :count)
      end
    end

    context "when algorithm is 'random'" do
      subject(:get_matching_exercise) { pe.get_matching_exercise(user) }

      let(:pe) { create(:proxy_exercise, algorithm: 'random', exercises: [chosen, other]) }
      let(:chosen) { create(:dummy) }
      let(:other) { create(:dummy) }

      before { allow(pe.exercises.target).to receive(:sample).and_return(chosen) }

      it { is_expected.to eql chosen }

      it 'uses exercises.sample and persists the assignment with a reason' do
        expect { get_matching_exercise }.to change(UserProxyExerciseExercise, :count).by(1)

        assignment = UserProxyExerciseExercise.last
        reason = JSON.parse(assignment.reason)
        expect(reason['reason']).to eq('random exercise requested')
        expect(assignment).to have_attributes(user: user, exercise: chosen, proxy_exercise: pe)
      end
    end

    context "when algorithm is 'best_match'" do
      subject(:get_matching_exercise) { pe.get_matching_exercise(user) }

      let(:pe) { create(:proxy_exercise, algorithm: 'best_match', exercises: [easy, hard]) }
      let(:easy) { create(:dummy, expected_difficulty: 1) }
      let(:hard) { create(:dummy, expected_difficulty: 2) }

      context 'when an error occurs' do
        before do
          allow(pe).to receive(:find_matching_exercise).and_raise(StandardError, 'boom')
          allow(pe.exercises.target).to receive(:sample).and_return(hard)
        end

        it { is_expected.to eql hard }

        it 'falls back to a random exercise with expected_difficulty > 1 and records the error in the reason' do
          expect { get_matching_exercise }.to change(UserProxyExerciseExercise, :count).by(1)

          reason = JSON.parse(UserProxyExerciseExercise.last.reason)
          expect(reason['reason']).to eq('fallback because of error')
          expect(reason['error']).to include('boom')
        end
      end

      context 'when the user has not seen any tags' do
        let(:easy) { create(:dummy, expected_difficulty: 1, tags: [build(:tag, name: 'arrays')]) }
        let(:hard) { create(:dummy, expected_difficulty: 2, tags: [build(:tag, name: 'hashes')]) }

        it { is_expected.to eql easy }

        it 'selects the easiest exercise and records the reason' do
          expect { get_matching_exercise }.to change(UserProxyExerciseExercise, :count).by(1)

          reason = JSON.parse(UserProxyExerciseExercise.last.reason)
          expect(reason['reason']).to eq('easiest exercise in pool. empty potential exercises')
        end
      end

      context 'when user has submission for exercise' do
        let(:tag) { build(:tag, name: 'loops') }
        let(:hard) { create(:dummy, expected_difficulty: 2, tags: [tag]) }

        before do
          create(:dummy, expected_difficulty: 1, tags: [tag])
          create(:dummy, expected_difficulty: 3, tags: [tag])
          create(:submission, cause: 'submit', exercise: build(:dummy, expected_difficulty: 2, tags: [tag]), contributor: user)
        end

        it { is_expected.to eql hard }

        it 'chooses the best matching exercise within the difficulty constraint and stores a detailed reason' do
          expect { get_matching_exercise }.to change(UserProxyExerciseExercise, :count).by(1)

          reason = JSON.parse(UserProxyExerciseExercise.last.reason)
          expect(reason['reason']).to eq('best matching exercise')
          expect(reason['highest_difficulty_user_has_accessed']).to eq(2)
          expect(reason).to have_key('current_users_knowledge_lack')
          expect(reason).to have_key('relative_knowledge_improvement')
        end
      end
    end
  end
end
