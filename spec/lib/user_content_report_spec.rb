# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserContentReport do
  subject(:report) { described_class.new(reported_content:) }

  describe '#related_request_for_comment' do
    context 'when a PfC is reported' do
      let(:reported_content) { build_stubbed(:rfc) }

      it 'returns the RfC itself' do
        expect(report.related_request_for_comment).to eq reported_content
      end
    end

    context 'when a comment is reported' do
      let(:rfc) { create(:rfc) }
      let(:reported_content) { create(:comment, file: rfc.file) }

      it 'returns the associated RfC' do
        expect(report.related_request_for_comment).to eq rfc
      end
    end
  end

  describe '#reported_message' do
    let(:message) { 'This message is reported.' }

    context 'when a comment is reported' do
      let(:reported_content) { build_stubbed(:comment, text: message) }

      it 'returns the comments text' do
        expect(report.reported_message).to eq message
      end
    end

    context 'when a PfC is reported' do
      let(:reported_content) { build_stubbed(:rfc, question: message) }

      it 'returns the RfCs question' do
        expect(report.reported_message).to eq message
      end
    end
  end

  describe '#course_url' do
    context 'when the LTI parameter is missing' do
      let(:reported_content) { build_stubbed(:rfc) }

      it 'returns no course URL' do
        expect(report.course_url).to be_nil
      end
    end

    context 'when the LTI parameter has no retrun URL' do
      let(:reported_content) { create(:rfc) }

      before do
        create(:lti_parameter, :without_return_url,
          exercise: reported_content.file.request_for_comment.exercise,
          study_group: reported_content.submission.study_group)
      end

      it 'returns no course URL' do
        expect(report.course_url).to be_nil
      end
    end

    context 'when the LTI parameter has the retrun URL' do
      let(:reported_content) { create(:rfc) }

      before do
        create(:lti_parameter,
          exercise: reported_content.file.request_for_comment.exercise,
          study_group: reported_content.submission.study_group)
      end

      it 'returns the LTI parameter course URL' do
        expect(report.course_url).to match(%r{https.+/courses/})
      end
    end
  end

  context 'when an unsupported model is reported' do
    let(:reported_content) { Exercise.new }

    it 'raise an error' do
      expect { report }.to raise_error('Exercise is not configured for content reports.')
    end
  end
end
