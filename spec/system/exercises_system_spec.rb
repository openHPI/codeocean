# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exercise creation', :js do
  let(:study_group) { create(:consumer).study_groups.find_by!(external_id: nil) }
  let(:teacher) { create(:teacher, study_groups: [study_group]) }
  let!(:ruby) { create(:ruby) }
  let(:submission_deadline) { 3.months.from_now.beginning_of_minute }
  let(:late_submission_deadline) { submission_deadline + 1.week }
  let(:title) { 'Ruby challenge' }
  let(:internal_title) { 'Project Ruby: Table flip' }

  let(:code) do
    <<~RUBY
      def self.❨╯°□°❩╯︵┻━┻
        puts "Calm down, bro"
      end
    RUBY
  end

  let(:description) do
    <<~TEXT
      Ruby challenge

      Do something with Ruby.
    TEXT
  end

  before do
    visit(sign_in_path)
    fill_in('email', with: teacher.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
    wait_for_turbolinks
    visit(exercises_path)
    click_on I18n.t('shared.new_model', model: Exercise.model_name.human)
    wait_for_turbolinks
  end

  it 'allows a teacher to create an exercise' do
    fill_in Exercise.human_attribute_name(:title), with: title
    fill_in Exercise.human_attribute_name(:internal_title), with: internal_title

    # description
    within('.markdown-editor__wrapper') do
      find('.ProseMirror').set(description)
    end

    chosen_select(Exercise.human_attribute_name(:execution_environment), ruby.name)

    chosen_date_time_select(Exercise.human_attribute_name(:submission_deadline), submission_deadline)

    chosen_date_time_select(Exercise.human_attribute_name(:late_submission_deadline), late_submission_deadline)

    check Exercise.human_attribute_name(:public)

    fill_in Exercise.human_attribute_name(:difficulty), with: 5

    click_on I18n.t('exercises.form.add_file')

    within(find_by_id('files').all('li').last) do
      fill_in CodeOcean::File.human_attribute_name(:name), with: 'main'

      chosen_select(CodeOcean::File.human_attribute_name(:file_type), ruby.file_type.name)
      chosen_select(CodeOcean::File.human_attribute_name(:role), I18n.t('code_ocean/files.roles.main_file'))

      check(CodeOcean::File.human_attribute_name(:read_only))

      find_by_id('editor-edit').click
      send_keys code.strip
    end

    click_button I18n.t('shared.create', model: Exercise.model_name.human)

    expect(page).to have_text 'Exercise has successfully been created.'

    # Exercise is created with expected attributes
    expect(page).to have_text(title)
    expect(page).to have_text(internal_title)
    expect(page).to have_text(submission_deadline.to_s)
    expect(page).to have_text(late_submission_deadline.to_s)

    # Exercise includes the code
    click_on 'main.rb'

    description.lines.each do |line|
      expect(page).to have_text(line.delete("\n"))
    end

    code.lines.each do |code_line|
      expect(page).to have_text(code_line.delete("\n"))
    end
  end

  def chosen_select(name, value)
    id = first('label', text: name)[:for]

    set_value_for_chosen_element(id, value)
  end

  def chosen_date_time_select(name, date)
    id = first('label', text: name)[:for]

    set_value_for_chosen_element("#{id}_1i", date.year.to_s)
    set_value_for_chosen_element("#{id}_2i", date.strftime('%B'))
    set_value_for_chosen_element("#{id}_3i", date.day.to_s)
    set_value_for_chosen_element("#{id}_4i", date.hour.to_s)
    set_value_for_chosen_element("#{id}_5i", date.min.to_s)
  end

  def set_value_for_chosen_element(id, value)
    element = find_by_id("#{id}_chosen")
    element.click

    within(element) do
      first('.chosen-results li', text: value).click
    end
  end
end
