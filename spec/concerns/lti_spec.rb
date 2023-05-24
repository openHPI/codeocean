# frozen_string_literal: true

require 'rails_helper'

class Controller < AnonymousController
  include Lti
end

RSpec.describe Lti do
  let(:controller) { Controller.new }
  let(:session) { double }

  describe '#build_tool_provider' do
    it 'instantiates a tool provider' do
      expect(IMS::LTI::ToolProvider).to receive(:new)
      controller.send(:build_tool_provider, consumer: build(:consumer), parameters: {})
    end
  end

  describe '#external_user_name' do
    let(:first_name) { 'Jane' }
    let(:last_name) { 'Doe' }
    let(:full_name) { 'John Doe' }
    let(:provider) { double }
    let(:provider_full) { instance_double(IMS::LTI::ToolProvider, lis_person_name_full: full_name) }

    context 'when a full name is provided' do
      it 'returns the full name' do
        allow(provider_full).to receive(:lis_person_name_full).and_return(full_name)
        expect(controller.send(:external_user_name, provider_full)).to eq(full_name)
      end
    end

    context 'when only partial information is provided' do
      it 'returns the first available name' do
        expect(provider).to receive(:lis_person_name_full)
        allow(provider).to receive(:lis_person_name_given).and_return(first_name)
        expect(provider).not_to receive(:lis_person_name_family)
        expect(controller.send(:external_user_name, provider)).to eq(first_name)
      end
    end
  end

  describe '#refuse_lti_launch' do
    it 'returns to the tool consumer' do
      message = I18n.t('sessions.oauth.invalid_consumer')
      expect(controller).to receive(:return_to_consumer).with(lti_errorlog: message, lti_errormsg: I18n.t('sessions.oauth.failure'))
      controller.send(:refuse_lti_launch, message:)
    end
  end

  describe '#return_to_consumer' do
    context 'with a return URL' do
      let(:consumer_return_url) { 'https://example.org' }
      let(:provider) { instance_double(IMS::LTI::ToolProvider, launch_presentation_return_url: consumer_return_url) }

      before { controller.instance_variable_set(:@provider, provider) }

      it 'redirects to the tool consumer' do
        expect(controller).to receive(:redirect_to).with(consumer_return_url, allow_other_host: true)
        controller.send(:return_to_consumer)
      end

      it 'passes messages to the consumer' do
        message = I18n.t('sessions.oauth.failure')
        expect(controller).to receive(:redirect_to).with("#{consumer_return_url}?lti_errorlog=#{CGI.escape(message)}", allow_other_host: true)
        controller.send(:return_to_consumer, lti_errorlog: message)
      end
    end

    context 'without a return URL' do
      before do
        allow(controller).to receive(:params).and_return({})
      end

      it 'redirects to the root URL' do
        expect(controller).to receive(:redirect_to).with(:root)
        controller.send(:return_to_consumer)
      end

      it 'displays alerts' do
        message = I18n.t('sessions.oauth.failure')
        controller.send(:return_to_consumer, lti_errormsg: message)
        expect(controller.instance_variable_get(:@flash)[:danger]).to eq(obtain_message(message))
      end

      it 'displays notices' do
        message = I18n.t('sessions.destroy_through_lti.success_without_outcome')
        controller.send(:return_to_consumer, lti_msg: message)
        expect(controller.instance_variable_get(:@flash)[:info]).to eq(obtain_message(message))
      end
    end
  end

  describe '#send_scores' do
    let(:consumer) { create(:consumer) }
    let(:score) { 0.5 }
    let(:submission) { create(:submission) }

    before do
      create(:lti_parameter, external_user: submission.contributor, exercise: submission.exercise)
    end

    context 'with an invalid score' do
      it 'raises an exception' do
        allow(submission).to receive(:normalized_score).and_return Lti::MAXIMUM_SCORE * 2
        expect { controller.send(:send_scores, submission) }.to raise_error(Lti::Error)
      end
    end

    context 'with an valid score' do
      context 'with a tool consumer' do
        context 'when grading is not supported' do
          it 'returns a corresponding status' do
            allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(false)
            allow(submission).to receive(:normalized_score).and_return score
            submit_info = controller.send(:send_scores, submission)
            expect(submit_info[:users][:all]).to eq(submit_info[:users][:unsupported])
          end
        end

        context 'when grading is supported' do
          let(:response) { double }
          let(:send_scores) { controller.send(:send_scores, submission) }
          let(:score_sent) { score }

          before do
            allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(true)
            allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score_sent).and_return(response)
            allow(response).to receive(:response_code).at_least(:once).and_return(200)
            allow(response).to receive(:post_response).and_return(response)
            allow(response).to receive(:body).at_least(:once).and_return('')
            allow(response).to receive(:code_major).at_least(:once).and_return('success')
            allow(submission).to receive(:normalized_score).and_return score
          end

          it 'sends the score' do
            expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score_sent)
            send_scores
          end

          it 'returns code, message, deadline and status' do
            expect(send_scores[:users][:all]).to eq(send_scores[:users][:success])
            expect(send_scores[:deadline]).to eq(:none)
            expect(send_scores[:detailed_results].first[:code]).to eq(response.response_code)
            expect(send_scores[:detailed_results].first[:message]).to eq(response.body)
            expect(send_scores[:detailed_results].first[:status]).to eq(response.code_major)
          end

          context 'when submission is before deadline' do
            before do
              allow(submission).to receive(:before_deadline?).and_return true
            end

            it 'returns deadline' do
              expect(send_scores[:deadline]).to eq(:before_deadline)
            end
          end

          context 'when submission is within grace period' do
            let(:score_sent) { score * 0.8 }

            before do
              allow(submission).to receive_messages(before_deadline?: false, within_grace_period?: true)
            end

            it 'returns deadline and reduced score' do
              expect(send_scores[:deadline]).to eq(:within_grace_period)
              expect(send_scores[:score][:sent]).to eq(score * 0.8)
            end

            it 'sends the reduced score' do
              expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score_sent)
              send_scores
            end
          end

          context 'when submission is after late deadline' do
            let(:score_sent) { score * 0 }

            before do
              allow(submission).to receive_messages(before_deadline?: false,
                within_grace_period?: false,
                after_late_deadline?: true)
            end

            it 'returns deadline and reduced score' do
              expect(send_scores[:deadline]).to eq(:after_late_deadline)
              expect(send_scores[:score][:sent]).to eq(score * 0)
            end

            it 'sends the reduced score' do
              expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score_sent)
              send_scores
            end
          end
        end

        context 'when transmission fails' do
          let(:send_scores) { controller.send(:send_scores, submission) }
          let(:score_sent) { 0 }

          before do
            allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(true)
            allow_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score_sent).and_raise(IMS::LTI::XMLParseError)
          end

          it 'does not raise an exception' do
            expect { send_scores }.not_to raise_error
          end

          it 'returns an error status' do
            expect(send_scores[:users][:all]).to eq(send_scores[:users][:error])
            expect(send_scores[:detailed_results].first[:status]).to eq('error')
          end
        end
      end

      context 'without a tool consumer' do
        it 'returns a corresponding status' do
          submission.contributor.consumer = nil

          allow(submission).to receive(:normalized_score).and_return score
          submit_info = controller.send(:send_scores, submission)
          expect(submit_info[:users][:all]).to eq(submit_info[:users][:unsupported])
        end
      end
    end
  end

  describe '#store_lti_session_data' do
    let(:parameters) { ActionController::Parameters.new({}) }

    it 'stores data in the session' do
      controller.instance_variable_set(:@current_user, create(:external_user))
      controller.instance_variable_set(:@exercise, create(:fibonacci))
      expect(controller.session).to receive(:[]=).with(:external_user_id, anything)
      expect(controller.session).to receive(:[]=).with(:pair_programming, anything)
      controller.send(:store_lti_session_data, parameters)
    end

    it 'creates an LtiParameter Object' do
      expect do
        controller.instance_variable_set(:@current_user, create(:external_user))
        controller.instance_variable_set(:@exercise, create(:fibonacci))
        controller.send(:store_lti_session_data, parameters)
      end.to change(LtiParameter, :count).by(1)
    end
  end

  describe '#store_nonce' do
    it 'adds a nonce to the nonce store' do
      nonce = SecureRandom.hex
      expect(NonceStore).to receive(:add).with(nonce)
      controller.send(:store_nonce, nonce)
    end
  end
end
