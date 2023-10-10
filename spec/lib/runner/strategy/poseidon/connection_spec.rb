# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Runner::Strategy::Poseidon::Connection do
  let(:runner_id) { attributes_for(:runner)[:runner_id] }
  let(:execution_environment) { create(:ruby) }
  let(:strategy) { Runner::Strategy::Poseidon.new(runner_id, execution_environment) }
  let(:connection_url) { 'wss://runners.example.org/websocket' }
  let(:connection) { described_class.new(connection_url, strategy, nil) }
  let(:websocket_client) { instance_double(Faye::WebSocket::Client) }

  before do
    allow(Faye::WebSocket::Client).to receive(:new).and_return(websocket_client)
    allow(websocket_client).to receive(:on)
    allow(websocket_client).to receive(:url).and_return(connection_url)
  end

  describe '#on_message' do
    subject(:process_message) { connection.send(:on_message, websocket_event, nil) }

    let(:websocket_event) { Faye::WebSocket::API::Event.create('message', data: message.to_json) }

    before { allow(connection).to receive(:on_message).and_call_original }

    shared_examples 'calls a message handler' do
      it 'calls the corresponding handler' do
        handler = "handle_#{message[:type]}".to_sym
        expect(connection).to receive(handler)
        process_message
      end
    end

    context "when type is 'start'" do
      let(:message) { {type: 'start'} }

      it_behaves_like 'calls a message handler'
    end

    context "when type is 'stdout'" do
      let(:message) { {type: 'stdout', data: 'Standard Output'} }

      it_behaves_like 'calls a message handler'
    end

    context "when type is 'stderr'" do
      let(:message) { {type: 'stderr', data: 'Standard Error'} }

      it_behaves_like 'calls a message handler'
    end

    context "when type is 'error'" do
      let(:message) { {type: 'error', data: 'Error'} }

      it_behaves_like 'calls a message handler'
    end

    context "when type is 'exit'" do
      let(:message) { {type: 'exit', data: 0} }

      it_behaves_like 'calls a message handler'
    end

    context "when type is 'timeout'" do
      let(:message) { {type: 'timeout'} }

      it_behaves_like 'calls a message handler'
    end
  end
end
