# frozen_string_literal: true

require 'rails_helper'

class Controller < AnonymousController
  include ScoringResultFormatting
end

describe ScoringResultFormatting do
  let(:controller) { Controller.new }
  let(:filename) { 'exercise.py' }
  let(:feedback_message) { '**good work**' }
  let(:outputs) { [{filename: filename, message: feedback_message}] }

  describe 'feedback message' do
    let(:new_feedback_message) { controller.format_scoring_results(outputs).first[:message] }

    context 'when the feedback message is not a path to a locale' do
      let(:feedback_message) { '**good work**' }

      it 'renders the feedback message as markdown' do
        expect(new_feedback_message).to match('<p><strong>good work</strong></p>')
      end
    end

    context 'when the feedback message is a valid path to a locale' do
      let(:feedback_message) { 'exercises.implement.default_test_feedback' }

      it 'replaces the feedback message with the locale' do
        expect(new_feedback_message).to eq(I18n.t(feedback_message))
      end
    end
  end

  describe 'filename' do
    let(:new_filename) { controller.format_scoring_results(outputs).first[:filename] }

    context 'when the filename is not a path to a locale' do
      let(:filename) { 'exercise.py' }

      it 'does not alter the filename' do
        expect(new_filename).to eq(filename)
      end
    end

    context 'when the filename is a valid path to a locale' do
      let(:filename) { 'exercises.implement.not_graded' }

      it 'replaces the filename with the locale' do
        expect(new_filename).to eq(I18n.t(filename))
      end
    end
  end
end
