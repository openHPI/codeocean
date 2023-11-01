# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteEvaluationController do
  let(:contributor) { create(:external_user) }
  let(:exercise) { create(:hello_world) }
  let(:programming_group) { nil }

  let(:validation_token) { create(:remote_evaluation_mapping, user: contributor, exercise:).validation_token }
  let(:files_attributes) { {'0': {file_id: exercise.files.find_by(role: 'main_file').id, content: ''}} }
  let(:remote_evaluation_params) { {remote_evaluation: {validation_token:, files_attributes:}} }

  let(:calculate_response) do
    [{
      status: :ok,
      stdout: '',
      stderr: '',
      waiting_for_container_time: 0,
      container_execution_time: 0,
      file_role: :teacher_defined_test,
      count: 1,
      failed: 0,
      error_messages: [],
      passed: 1,
      score:,
      filename: 'exercise_spec.rb',
      message: 'Well done.',
      weight: 1.0,
      hidden_feedback: false,
      exit_code: 0,
    }]
  end

  shared_examples 'response' do |info|
    it 'returns a message and a status' do
      options = {}
      options[:score_sent] = (score_sent * 100).to_i if defined? score_sent
      options[:score] = (score * 100).to_i if defined? score
      options[:user] = users_error.map(&:displayname).join(', ') if defined? users_error
      options[:consumer] = contributor.consumer.name if defined? contributor

      expect(response.parsed_body.symbolize_keys[:message]).to eq(I18n.t(info[:message], **options))
      expect(response.parsed_body.symbolize_keys[:status]).to eq(info[:status])
    end
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(contributor)
  end

  describe '#POST submit' do
    let(:perform_request) { proc { post :submit, params: remote_evaluation_params } }

    let(:scoring_response) do
      {
        users: {all: users_success + users_error + users_unsupported, success: users_success, error: users_error, unsupported: users_unsupported},
        score: {original: score, sent: score_sent},
        deadline:,
        detailed_results: [],
      }
    end

    context 'when remote evaluation mapping is available' do
      context 'when the scoring is successful' do
        let(:score) { 1 }
        let(:score_sent) { score }
        let(:deadline) { :none }

        before do
          allow_any_instance_of(Submission).to receive_messages(calculate_score: calculate_response, score:)
          allow_any_instance_of(described_class).to receive(:send_scores).and_return(scoring_response)
          perform_request.call
        end

        context 'when no LTI transmission was attempted' do
          let(:users_success) { [] }
          let(:users_error) { [] }
          let(:users_unsupported) { [contributor] }

          it_behaves_like 'response', {message: 'exercises.editor.submit_failure_remote', status: 410}
        end

        context 'when transmission of points failed for all users' do
          let(:users_success) { [] }
          let(:users_error) { [contributor] }
          let(:users_unsupported) { [] }

          it_behaves_like 'response', {message: 'exercises.editor.submit_failure_all', status: 424}
        end

        context 'when transmission of points failed for some users' do
          let(:users_success) { [contributor] }
          let(:users_error) { [create(:external_user)] }
          let(:users_unsupported) { [] }

          it_behaves_like 'response', {message: 'exercises.editor.submit_failure_other_users', status: 417}
        end

        context 'when the scoring was too late' do
          let(:users_success) { [contributor] }
          let(:users_error) { [] }
          let(:users_unsupported) { [] }
          let(:deadline) { :within_grace_period }
          let(:score_sent) { score * 0.8 }

          it_behaves_like 'response', {message: 'exercises.editor.submit_too_late', status: 207}

          it 'sends a reduced score' do
            expect(response.parsed_body.symbolize_keys[:score]).to eq((score_sent * 100).to_i)
          end
        end

        context 'when transmission of points was successful' do
          let(:users_success) { [contributor] }
          let(:users_error) { [] }
          let(:users_unsupported) { [] }

          context 'when exercise is finished' do
            it_behaves_like 'response', {message: 'exercises.editor.exercise_finished_remote', status: 200}
          end

          context 'when exercise is not finished' do
            let(:score) { 0.5 }

            it_behaves_like 'response', {message: 'sessions.destroy_through_lti.success_with_outcome', status: 202}
          end
        end
      end

      context 'when the scoring was not successful' do
        let(:users_success) { [contributor] }
        let(:users_error) { [] }
        let(:users_unsupported) { [] }

        before do
          allow_any_instance_of(Submission).to receive(:calculate_score).and_raise(error)
          perform_request.call
        end

        context 'when the desired runner is already in use' do
          let(:error) { Runner::Error::RunnerInUse }

          it_behaves_like 'response', {message: 'exercises.editor.runner_in_use', status: 409}
        end

        context 'when no runner is available' do
          let(:error) { Runner::Error::NotAvailable }

          it_behaves_like 'response', {message: 'exercises.editor.depleted', status: 503}
        end
      end
    end

    context 'when remote evaluation mapping is not available' do
      let(:validation_token) { nil }

      before { perform_request.call }

      it_behaves_like 'response', {message: 'exercises.editor.submit_no_validation_token', status: 401}
    end
  end

  describe '#POST evaluate' do
    let(:perform_request) { proc { post :evaluate, params: remote_evaluation_params } }

    context 'when remote evaluation mapping is available' do
      context 'when the scoring is successful' do
        let(:score) { 1 }

        before do
          allow_any_instance_of(Submission).to receive_messages(calculate_score: calculate_response, score:)
          perform_request.call
        end

        it 'returns the feedback' do
          expect(response.body).to eq(calculate_response.to_json)
        end
      end

      context 'when the scoring was not successful' do
        let(:users_success) { [contributor] }
        let(:users_error) { [] }
        let(:users_unsupported) { [] }

        before do
          allow_any_instance_of(Submission).to receive(:calculate_score).and_raise(error)
          perform_request.call
        end

        context 'when the desired runner is already in use' do
          let(:error) { Runner::Error::RunnerInUse }

          it_behaves_like 'response', {message: 'exercises.editor.runner_in_use', status: 409}
        end

        context 'when no runner is available' do
          let(:error) { Runner::Error::NotAvailable }

          it_behaves_like 'response', {message: 'exercises.editor.depleted', status: 503}
        end
      end
    end

    context 'when remote evaluation mapping is not available' do
      let(:validation_token) { nil }

      before { perform_request.call }

      it_behaves_like 'response', {message: 'exercises.editor.submit_no_validation_token', status: 401}
    end
  end
end
