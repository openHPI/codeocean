# frozen_string_literal: true

require 'rack/file'
require 'capybara/rspec'

AUDIO_FILENAME = 'chai.ogg'
VIDEO_FILENAME = 'devstories.mp4'

Capybara.app = Rack::File.new(File.dirname(__FILE__))

describe 'index.html', type: :feature do
  before(:each) { visit('index.html') }

  it 'contains an audio element' do
    expect(page).to have_css('audio')
  end

  it 'plays the correct audio file' do
    expect(page).to have_css("audio[src='#{AUDIO_FILENAME}']")
  end

  it 'contains a video element' do
    expect(page).to have_css('video')
  end

  it 'plays the correct video file' do
    expect(page).to have_css("video[src='#{VIDEO_FILENAME}']")
  end
end
