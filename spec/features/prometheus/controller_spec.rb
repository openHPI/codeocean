# frozen_string_literal: true

require 'rails_helper'

describe Prometheus::Controller do
  let(:codeocean_config) { instance_double(CodeOcean::Config) }
  let(:prometheus_config) { {prometheus_exporter: {enabled: true}} }

  def stub_metrics
    metrics = %i[@instance_count @rfc_count @rfc_commented_count]
    %i[increment decrement observe].each do |method|
      metrics.each do |metric|
        allow(described_class.instance_variable_get(metric)).to receive(method)
      end
    end
  end

  before do
    allow(CodeOcean::Config).to receive(:new).with(:code_ocean).and_return(codeocean_config)
    allow(codeocean_config).to receive(:read).and_return(prometheus_config)

    ApplicationRecord.include Prometheus::Record
    described_class.initialize_metrics
    stub_metrics
  end

  describe 'instance count' do
    it 'initializes the metrics with the current database entries' do
      create_list(:proxy_exercise, 3)
      described_class.register_metrics
      stub_metrics
      described_class.initialize_instance_count
      expect(described_class.instance_variable_get(:@instance_count)).to(have_received(:observe).with(ProxyExercise.count, class: ProxyExercise.name).once)
    end

    it 'gets notified when an object is created' do
      allow(described_class).to receive(:create_notification)
      proxy_exercise = create(:proxy_exercise)
      expect(described_class).to have_received(:create_notification).with(proxy_exercise).once
    end

    it 'gets notified when an object is destroyed' do
      allow(described_class).to receive(:destroy_notification)
      proxy_exercise = create(:proxy_exercise).destroy
      expect(described_class).to have_received(:destroy_notification).with(proxy_exercise).once
    end

    it 'increments gauge when creating a new instance' do
      create(:proxy_exercise)
      expect(described_class.instance_variable_get(:@instance_count)).to(
        have_received(:increment).with(class: ProxyExercise.name).once
      )
    end

    it 'decrements gauge when deleting an object' do
      create(:proxy_exercise).destroy
      expect(described_class.instance_variable_get(:@instance_count)).to(
        have_received(:decrement).with(class: ProxyExercise.name).once
      )
    end
  end

  describe 'rfc count' do
    context 'when initializing an rfc' do
      it 'updates rfc count when creating an ongoing rfc' do
        create(:rfc)
        expect(described_class.instance_variable_get(:@rfc_count)).to(
          have_received(:increment).with(state: RequestForComment::ONGOING).once
        )
      end
    end

    context 'when changing the state of an rfc' do
      let(:rfc) { create(:rfc) }

      it 'updates rfc count when soft-solving an rfc' do
        rfc.full_score_reached = true
        rfc.save
        expect(described_class.instance_variable_get(:@rfc_count)).to(have_received(:increment).with(state: RequestForComment::SOFT_SOLVED).once)
        expect(described_class.instance_variable_get(:@rfc_count)).to(have_received(:decrement).with(state: RequestForComment::ONGOING).once)
      end

      it 'updates rfc count when solving an rfc' do
        rfc.solved = true
        rfc.save
        expect(described_class.instance_variable_get(:@rfc_count)).to(have_received(:increment).with(state: RequestForComment::SOLVED).once)
        expect(described_class.instance_variable_get(:@rfc_count)).to(have_received(:decrement).with(state: RequestForComment::ONGOING).once)
      end
    end

    context 'when commenting an rfc' do
      it 'updates comment metric when commenting an rfc' do
        create(:rfc_with_comment)
        expect(described_class.instance_variable_get(:@rfc_commented_count)).to have_received(:increment).once
      end

      it 'does not update comment metric when commenting an rfc that already has a comment' do
        rfc = create(:rfc_with_comment)
        expect(described_class.instance_variable_get(:@rfc_commented_count)).to have_received(:increment).once

        Comment.create(file: rfc.file, user: rfc.user, text: "comment a for rfc #{rfc.question}")
        Comment.create(file: rfc.file, user: rfc.user, text: "comment b for rfc #{rfc.question}")
        # instance count has only been updated for the creation of the commented rfc and not for additional comments
        expect(described_class.instance_variable_get(:@rfc_commented_count)).to have_received(:increment).once
      end
    end
  end
end
