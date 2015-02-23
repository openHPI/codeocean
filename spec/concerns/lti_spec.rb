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
      controller.send(:build_tool_provider, consumer: FactoryGirl.build(:consumer), parameters: {})
    end
  end

  describe '#clear_lti_session_data' do
    it 'clears the session' do
      expect(controller.session).to receive(:delete).with(:consumer_id)
      expect(controller.session).to receive(:delete).with(:external_user_id)
      expect(controller.session).to receive(:delete).with(:lti_parameters)
      controller.send(:clear_lti_session_data)
    end
  end

  describe '#external_user_name' do
    let(:first_name) { 'Jane' }
    let(:full_name) { 'John Doe' }
    let(:last_name) { 'Doe' }
    let(:provider) { double }

    context 'when a full name is provided' do
      it 'returns the full name' do
        expect(provider).to receive(:lis_person_name_full).twice.and_return(full_name)
        expect(controller.send(:external_user_name, provider)).to eq(full_name)
      end
    end

    context 'when first and last name are provided' do
      it 'returns the concatenated names' do
        expect(provider).to receive(:lis_person_name_full)
        expect(provider).to receive(:lis_person_name_given).twice.and_return(first_name)
        expect(provider).to receive(:lis_person_name_family).twice.and_return(last_name)
        expect(controller.send(:external_user_name, provider)).to eq("#{first_name} #{last_name}")
      end
    end

    context 'when only partial information is provided' do
      it 'returns the first available name' do
        expect(provider).to receive(:lis_person_name_full)
        expect(provider).to receive(:lis_person_name_given).twice.and_return(first_name)
        expect(provider).to receive(:lis_person_name_family)
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
    let(:consumer) { FactoryGirl.create(:consumer) }
    let(:score) { 0.5 }

    context 'with an invalid score' do
      it 'raises an exception' do
        expect { controller.send(:send_score, Lti::MAXIMUM_SCORE * 2) }.to raise_error(Lti::Error)
      end
    end

    context 'with an valid score' do
      context 'with a tool provider' do
        before(:each) do
          controller.session[:consumer_id] = consumer.id
          controller.session[:lti_parameters] = {}
        end

        context 'when grading is not supported' do
          it 'returns a corresponding status' do
            expect_any_instance_of(IMS::LTI::ToolProvider).to receive(:outcome_service?).and_return(false)
            expect(controller.send(:send_score, score)[:status]).to eq('unsupported')
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
            controller.send(:send_score, score)
          end

          it 'returns code, message, and status' do
            result = controller.send(:send_score, score)
            expect(result[:code]).to eq(response.response_code)
            expect(result[:message]).to eq(response.body)
            expect(result[:status]).to eq(response.code_major)
          end
        end
      end

      context 'without a tool provider' do
        it 'returns a corresponding status' do
          expect(controller).to receive(:build_tool_provider).and_return(nil)
          expect(controller.send(:send_score, score)[:status]).to eq('error')
        end
      end
    end
  end

  describe '#store_lti_session_data' do
    let(:parameters) { {} }
    before(:each) { controller.instance_variable_set(:@current_user, FactoryGirl.create(:external_user)) }
    after(:each) { controller.send(:store_lti_session_data, consumer: FactoryGirl.build(:consumer), parameters: parameters) }

    it 'stores data in the session' do
      expect(controller.session).to receive(:[]=).with(:consumer_id, anything)
      expect(controller.session).to receive(:[]=).with(:external_user_id, anything)
      expect(controller.session).to receive(:[]=).with(:lti_parameters, kind_of(Hash))
    end

    it 'stores only selected tuples' do
      expect(parameters).to receive(:slice).with(*Lti::SESSION_PARAMETERS)
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
