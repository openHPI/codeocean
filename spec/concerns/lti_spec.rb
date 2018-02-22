require 'rails_helper'

class Controller < AnonymousController
  include Lti
end

describe Lti do
  let(:controller) { Controller.new }
  let(:session) { double }

  describe '#build_tool_provider' do
    it 'instantiates a tool provider' do
      expect(IMS::LTI::ToolProvider).to receive(:new)
      controller.send(:build_tool_provider, consumer: FactoryBot.build(:consumer), parameters: {})
    end
  end

  describe '#clear_lti_session_data' do
    it 'clears the session' do
      expect(controller.session).to receive(:delete).with(:consumer_id)
      expect(controller.session).to receive(:delete).with(:external_user_id)
      controller.send(:clear_lti_session_data)
    end
  end

  describe '#external_user_name' do
    let(:first_name) { 'Jane' }
    let(:last_name) { 'Doe' }
    let(:full_name) { 'John Doe' }
    let(:provider) { double }
    let(:provider_full) { double(:lis_person_name_full => full_name) }

    context 'when a full name is provided' do
      it 'returns the full name' do
        expect(provider_full).to receive(:lis_person_name_full).twice.and_return(full_name)
        expect(controller.send(:external_user_name, provider_full)).to eq(full_name)
      end
    end

    context 'when only partial information is provided' do
      it 'returns the first available name' do
        expect(provider).to receive(:lis_person_name_full)
        expect(provider).to receive(:lis_person_name_given).and_return(first_name)
        expect(provider).not_to receive(:lis_person_name_family)
        expect(controller.send(:external_user_name, provider)).to eq(first_name)
      end
    end
  end

  describe '#refuse_lti_launch' do
    it 'returns to the tool consumer' do
      message = I18n.t('sessions.oauth.invalid_consumer')
      expect(controller).to receive(:return_to_consumer).with(lti_errorlog: message, lti_errormsg: I18n.t('sessions.oauth.failure'))
      controller.send(:refuse_lti_launch, message: message)
    end
  end

  describe '#return_to_consumer' do
    context 'with a return URL' do
      let(:consumer_return_url) { 'http://example.org' }
      before(:each) { expect(controller).to receive(:params).and_return(launch_presentation_return_url: consumer_return_url) }

      it 'redirects to the tool consumer' do
        expect(controller).to receive(:redirect_to).with(consumer_return_url)
        controller.send(:return_to_consumer)
      end

      it 'passes messages to the consumer' do
        message = I18n.t('sessions.oauth.failure')
        expect(controller).to receive(:redirect_to).with("#{consumer_return_url}?lti_errorlog=#{CGI.escape(message)}")
        controller.send(:return_to_consumer, lti_errorlog: message)
      end
    end

    context 'without a return URL' do
      before(:each) do
        expect(controller).to receive(:params).and_return({})
        expect(controller).to receive(:redirect_to).with(:root)
      end

      it 'redirects to the root URL' do
        controller.send(:return_to_consumer)
      end

      it 'displays alerts' do
        message = I18n.t('sessions.oauth.failure')
        controller.send(:return_to_consumer, lti_errormsg: message)
      end

      it 'displays notices' do
        message = I18n.t('sessions.oauth.success')
        controller.send(:return_to_consumer, lti_msg: message)
      end
    end
  end

  describe '#send_score' do
    let(:consumer) { FactoryBot.create(:consumer) }
    let(:score) { 0.5 }
    let(:submission) { FactoryBot.create(:submission) }
    let!(:lti_parameter) { FactoryBot.create(:lti_parameter, consumers_id: consumer.id, external_users_id: submission.user_id, exercises_id: submission.exercise_id)}

    context 'with an invalid score' do
      it 'raises an exception' do
        expect { controller.send(:send_score, submission.exercise_id, Lti::MAXIMUM_SCORE * 2, submission.user_id) }.to raise_error(Lti::Error)
      end
    end

    context 'with an valid score' do
      context 'with a tool consumer' do
        before(:each) do
          controller.session[:consumer_id] = consumer.id
        end

        context 'when grading is not supported' do
          it 'returns a corresponding status' do
            expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(false)
            expect(controller.send(:send_score, submission.exercise_id, score, submission.user_id)[:status]).to eq('unsupported')
          end
        end

        context 'when grading is supported' do
          let(:response) { double }

          before(:each) do
            expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(true)
            expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:post_replace_result!).with(score).and_return(response)
            expect(response).to receive(:response_code).at_least(:once).and_return(200)
            expect(response).to receive(:post_response).and_return(response)
            expect(response).to receive(:body).at_least(:once).and_return('')
            expect(response).to receive(:code_major).at_least(:once).and_return('success')
          end

          it 'sends the score' do
            controller.send(:send_score, submission.exercise_id, score, submission.user_id)
          end

          it 'returns code, message, and status' do
            result = controller.send(:send_score, submission.exercise_id, score, submission.user_id)
            expect(result[:code]).to eq(response.response_code)
            expect(result[:message]).to eq(response.body)
            expect(result[:status]).to eq(response.code_major)
          end
        end
      end

      context 'without a tool consumer' do
        it 'returns a corresponding status' do
          expect(controller.send(:send_score, submission.exercise_id, score, submission.user_id)[:status]).to eq('error')
        end
      end
    end
  end

  describe '#store_lti_session_data' do
    let(:parameters) { {} }

    it 'stores data in the session' do
      controller.instance_variable_set(:@current_user, FactoryBot.create(:external_user))
      controller.instance_variable_set(:@exercise, FactoryBot.create(:fibonacci))
      expect(controller.session).to receive(:[]=).with(:consumer_id, anything)
      expect(controller.session).to receive(:[]=).with(:external_user_id, anything)
      controller.send(:store_lti_session_data, consumer: FactoryBot.build(:consumer), parameters: parameters)
    end

    it 'it creates an LtiParameter Object' do
      before_count = LtiParameter.count
      controller.instance_variable_set(:@current_user, FactoryBot.create(:external_user))
      controller.instance_variable_set(:@exercise, FactoryBot.create(:fibonacci))
      controller.send(:store_lti_session_data, consumer: FactoryBot.build(:consumer), parameters: parameters)
      expect(LtiParameter.count).to eq(before_count + 1)
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
