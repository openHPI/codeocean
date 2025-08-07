# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserContentReport do
  describe '#related_request_for_comment' do
    it 'returns the RfC when the RfC itself is reported' do
      rfc = build_stubbed(:rfc)

      expect(described_class.new(reported_content: rfc).related_request_for_comment).to eq rfc
    end

    it 'returns the associated RfC when a comment is reported' do
      rfc = create(:rfc)
      comment = create(:comment, file: rfc.file)
      expect(described_class.new(reported_content: comment).related_request_for_comment).to eq rfc
    end
  end

  describe '#reported_message' do
    let(:message) { 'This message is reported.' }

    it 'returns the comments text' do
      comment = build_stubbed(:comment, text: message)

      expect(described_class.new(reported_content: comment).reported_message).to eq message
    end

    it 'returns the RfCs question' do
      rfc = build_stubbed(:rfc, question: message)

      expect(described_class.new(reported_content: rfc).reported_message).to eq message
    end
  end

  describe '#course_url' do
    it 'has no course URL if the LTI parameters are absent' do
      rfc = build_stubbed(:rfc)

      expect(described_class.new(reported_content: rfc).course_url).to be_nil
    end

    it 'has no course URL if the required LTI attribute is missing' do
      rfc = create(:rfc)

      create(:lti_parameter, :without_return_url,
        exercise: rfc.file.request_for_comment.exercise,
        study_group: rfc.submission.study_group)

      expect(described_class.new(reported_content: rfc).course_url).to be_nil
    end

    it 'returns the LTI parameter course URL' do
      rfc = create(:rfc)

      create(:lti_parameter,
        exercise: rfc.file.request_for_comment.exercise,
        study_group: rfc.submission.study_group)

      expect(described_class.new(reported_content: rfc).course_url).to match(%r{https.+/courses/})
    end
  end

  it 'raise an error if an unsupported model is reported' do
    expect { described_class.new(reported_content: Exercise.new) }.to raise_error('Exercise is not configured for content reports.')
  end
end
