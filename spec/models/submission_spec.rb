require 'rails_helper'

describe Submission do
  let(:submission) { FactoryGirl.create(:submission, exercise: FactoryGirl.create(:dummy)) }

  it 'validates the presence of a cause' do
    expect(described_class.create.errors[:cause]).to be_present
  end

  it 'validates the presence of an exercise' do
    expect(described_class.create.errors[:exercise_id]).to be_present
  end

  it 'validates the presence of a user' do
    expect(described_class.create.errors[:user_id]).to be_present
    expect(described_class.create.errors[:user_type]).to be_present
  end

  [:render, :run, :test].each do |action|
    describe "##{action}_url" do
      let(:url) { submission.send(:"#{action}_url") }

      it "starts like the #{action} path" do
        filename = File.basename(__FILE__)
        expect(url).to start_with(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission, filename).sub(filename, ''))
      end

      it 'ends with a placeholder' do
        expect(url).to end_with(Submission::FILENAME_URL_PLACEHOLDER)
      end
    end
  end

  describe '#main_file' do
    let(:submission) { FactoryGirl.create(:submission) }

    it "returns the submission's main file" do
      expect(submission.main_file).to be_a(CodeOcean::File)
      expect(submission.main_file.main_file?).to be true
    end
  end

  describe '#normalized_score' do
    context 'with a score' do
      let(:submission) { FactoryGirl.create(:submission) }
      before(:each) { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score as a value between 0 and 1' do
        expect(0..1).to include(submission.normalized_score)
      end
    end

    context 'without a score' do
      before(:each) { submission.score = nil }

      it 'returns 0' do
        expect(submission.normalized_score).to be 0
      end
    end
  end

  describe '#percentage' do
    context 'with a score' do
      let(:submission) { FactoryGirl.create(:submission) }
      before(:each) { submission.score = submission.exercise.maximum_score / 2 }

      it 'returns the score expressed as a percentage' do
        expect(0..100).to include(submission.percentage)
      end
    end

    context 'without a score' do
      before(:each) { submission.score = nil }

      it 'returns 0' do
        expect(submission.percentage).to be 0
      end
    end
  end

  [:score, :stop].each do |action|
    describe "##{action}_url" do
      let(:url) { submission.send(:"#{action}_url") }

      it "corresponds to the #{action} path" do
        expect(url).to eq(Rails.application.routes.url_helpers.send(:"#{action}_submission_path", submission))
      end
    end
  end

  describe '#siblings' do
    let(:siblings) { described_class.find_by(user: user).siblings }
    let(:user) { FactoryGirl.create(:external_user) }

    before(:each) do
      10.times.each_with_index do |_, index|
        FactoryGirl.create(:submission, exercise: submission.exercise, user: (index.even? ? user : FactoryGirl.create(:external_user)))
      end
    end

    it "returns all the creator's submissions for the same exercise" do
      expect(siblings).to be_an(ActiveRecord::Relation)
      expect(siblings.map(&:exercise).uniq).to eq([submission.exercise])
      expect(siblings.map(&:user).uniq).to eq([user])
    end
  end

  describe '#to_s' do
    it "equals the class' model name" do
      expect(submission.to_s).to eq(described_class.model_name.human)
    end
  end
end
