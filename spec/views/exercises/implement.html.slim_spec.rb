require 'rails_helper'

describe 'exercises/implement.html.slim' do
  let(:exercise) { FactoryBot.create(:fibonacci) }
  let(:files) { exercise.files.visible }
  let(:non_binary_files) { files.reject { |file| file.file_type.binary? } }

  before(:each) do
    assign(:current_user, FactoryBot.create(:admin))
    assign(:exercise, exercise)
    assign(:files, files)
    assign(:paths, [])
    render
  end

  it 'contains the required editor data attributes' do
    expect(rendered).to have_css("#editor[data-errors-url='#{execution_environment_errors_path(exercise.execution_environment)}']")
    expect(rendered).to have_css("#editor[data-exercise-id='#{exercise.id}']")
    expect(rendered).to have_css('#editor[data-message-timeout]')
    expect(rendered).to have_css("#editor[data-submissions-url='#{submissions_path}']")
  end

  it 'contains the required file tree data attributes' do
    expect(rendered).to have_css('#files[data-entries]')
  end

  it 'contains a frame for every file' do
    expect(rendered).to have_css('.frame', count: files.length)
  end

  it 'assigns the correct code to every editor' do
    non_binary_files.each do |file|
      expect(rendered).to include(file.content)
    end
  end

  it 'assigns the correct data attributes to every frame' do
    non_binary_files.each do |file|
      expect(rendered).to have_css(".editor[data-file-id='#{file.id}'][data-indent-size='#{file.file_type.indent_size}'][data-mode='#{file.file_type.editor_mode}']")
      expect(rendered).to have_css(".frame[data-filename='#{file.name_with_extension}']")
    end
  end
end
