# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Score', :js do
  let(:exercise) { create(:hello_world) }
  let(:contributor) { create(:external_user) }
  let(:submission) { create(:submission, exercise:, contributor:, score:) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(contributor)
    allow(Submission).to receive(:find).and_return(submission)
    visit(implement_exercise_path(exercise))
  end

  shared_examples 'exercise finished notification' do
    it "shows an 'exercise finished' notification" do
      # Text needs to be split because it includes the embedded URL in the HTML which is not shown in the notification.
      # We compare the shown notification text and the URL separately.
      expect(page).to have_content(I18n.t('exercises.editor.exercise_finished').split('.').first)
      expect(page).to have_link(nil, href: finalize_submission_path(submission))
    end
  end

  shared_examples 'no exercise finished notification' do
    it "does not show an 'exercise finished' notification" do
      # Text needs to be split because it includes the embedded URL in the HTML which is not shown in the notification.
      # We compare the shown notification text and the URL separately.
      expect(page).to have_no_content(I18n.t('exercises.editor.exercise_finished').split('.').first)
      expect(page).to have_no_link(nil, href: finalize_submission_path(submission))
    end
  end

  shared_examples 'notification' do |message_key|
    it "shows a '#{message_key.split('.').last}' notification" do
      options = {}
      options[:score_sent] = (score_sent * 100).to_i if defined? score_sent
      options[:user] = users_error.map(&:displayname).join(', ') if defined? users_error

      expect(page).to have_content(I18n.t(message_key, **options))
    end
  end

  shared_examples 'no notification' do |message_key|
    it "does not show a '#{message_key.split('.').last}' notification" do
      expect(page).to have_no_content(I18n.t(message_key))
    end
  end

  context 'when scoring is successful' do
    let(:lti_outcome_service?) { true }

    let(:scoring_response) do
      {
        users: {all: users_success + users_error + users_unsupported, success: users_success, error: users_error, unsupported: users_unsupported},
        score: {original: score, sent: score_sent},
        deadline:,
        detailed_results: [],
      }
    end

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

    before do
      allow_any_instance_of(LtiHelper).to receive(:lti_outcome_service?).and_return(lti_outcome_service?)
      allow(submission).to receive(:calculate_score).and_return(calculate_response)
      allow_any_instance_of(SubmissionsController).to receive(:send_scores).and_return(scoring_response)
      click_on(I18n.t('exercises.editor.score'))
    end

    shared_context 'when full score reached' do
      let(:score) { 1 }
    end

    shared_context 'when full score is not reached' do
      let(:score) { 0 }
    end

    shared_context 'when scored without deadline' do
      let(:deadline) { :none }
      let(:score_sent) { score }
    end

    shared_context 'when scored before deadline' do
      let(:deadline) { :before_deadline }
      let(:score_sent) { score }
    end

    shared_context 'when scored within grace period' do
      let(:deadline) { :within_grace_period }
      let(:score_sent) { score * 0.8 }
    end

    shared_context 'when scored after late deadline' do
      let(:deadline) { :after_late_deadline }
      let(:score_sent) { score * 0 }
    end

    context 'when the LTI outcome service is supported' do
      describe 'LTI failure' do
        let(:users_success) { [] }
        let(:users_error) { [contributor] }
        let(:users_unsupported) { [] }

        context 'when full score is reached' do
          include_context 'when full score reached'

          %w[without_deadline before_deadline within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'no exercise finished notification'
              it_behaves_like 'notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
            end
          end
        end

        context 'when full score is not reached' do
          include_context 'when full score is not reached'

          %w[without_deadline before_deadline within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'no exercise finished notification'
              it_behaves_like 'notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
            end
          end
        end
      end

      describe 'LTI success' do
        let(:users_success) { [contributor] }
        let(:users_error) { [] }
        let(:users_unsupported) { [] }

        context 'when full score is reached' do
          include_context 'when full score reached'

          %w[without_deadline before_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
            end
          end

          %w[within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'notification', 'exercises.editor.submit_too_late'
            end
          end
        end

        context 'when full score is not reached' do
          include_context 'when full score is not reached'

          %w[within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'no exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'notification', 'exercises.editor.submit_too_late'
            end
          end
        end
      end

      describe 'LTI success for current contributor and failure for other' do
        let(:users_success) { [contributor] }
        let(:users_error) { [create(:external_user)] }
        let(:users_unsupported) { [] }

        context 'when full score is reached' do
          include_context 'when full score reached'

          %w[without_deadline before_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
            end
          end

          %w[within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'notification', 'exercises.editor.submit_too_late'
            end
          end
        end

        context 'when full score is not reached' do
          include_context 'when full score is not reached'

          %w[within_grace_period after_late_deadline].each do |scenario|
            context "when scored #{scenario.tr('_', ' ')}" do
              include_context "when scored #{scenario.tr('_', ' ')}"

              it_behaves_like 'no exercise finished notification'
              it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
              it_behaves_like 'notification', 'exercises.editor.submit_failure_other_users'
              it_behaves_like 'notification', 'exercises.editor.submit_too_late'
            end
          end
        end
      end
    end

    context 'when the LTI outcomes are not supported' do
      let(:lti_outcome_service?) { false }
      let(:users_success) { [] }
      let(:users_error) { [] }
      let(:users_unsupported) { [contributor] }

      context 'when full score is reached' do
        include_context 'when full score reached'

        %w[without_deadline before_deadline within_grace_period after_late_deadline].each do |scenario|
          context "when scored #{scenario.tr('_', ' ')}" do
            include_context "when scored #{scenario.tr('_', ' ')}"

            it_behaves_like 'exercise finished notification'
            it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
            it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
            it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
          end
        end
      end

      context 'when full score is not reached' do
        include_context 'when full score is not reached'

        %w[without_deadline before_deadline within_grace_period after_late_deadline].each do |scenario|
          context "when scored #{scenario.tr('_', ' ')}" do
            include_context "when scored #{scenario.tr('_', ' ')}"

            it_behaves_like 'no exercise finished notification'
            it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
            it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
            it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
          end
        end
      end
    end
  end

  context 'when scoring is not successful' do
    let(:score) { 0 }

    context 'when the desired runner is already in use' do
      before do
        allow(submission).to receive(:calculate_score).and_raise(Runner::Error::RunnerInUse)
        click_on(I18n.t('exercises.editor.score'))
      end

      it_behaves_like 'notification', 'exercises.editor.runner_in_use'
      it_behaves_like 'no exercise finished notification'
      it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
      it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
      it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
    end

    context 'when no runner is available' do
      before do
        allow(submission).to receive(:calculate_score).and_raise(Runner::Error::NotAvailable)
        click_on(I18n.t('exercises.editor.score'))
      end

      it_behaves_like 'notification', 'exercises.editor.depleted'
      it_behaves_like 'no exercise finished notification'
      it_behaves_like 'no notification', 'exercises.editor.submit_failure_all'
      it_behaves_like 'no notification', 'exercises.editor.submit_failure_other_users'
      it_behaves_like 'no notification', 'exercises.editor.submit_too_late'
    end
  end
end
