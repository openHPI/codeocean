require 'rails_helper'
require 'nokogiri'

describe Proforma::XmlGenerator do

  let (:generator) { described_class.new}
  let (:exercise) { FactoryBot.create(:codeharbor_test)}
  let(:xml) {
    ::Nokogiri::XML(
        generator.generate_xml(exercise)
    ).xpath('/p:task')[0]
  }

  describe '#to_proforma_xml' do

    describe 'meta data' do

      it 'has single <p:description> tag which contains description' do
        description = xml.xpath('p:description')
        expect(description.size()).to be 1
        expect(description.first.text).to eq exercise.description
      end


      it 'has single <p:meta-data> tag' do
        metaData = xml.xpath('p:meta-data')
        expect(metaData.size()).to be 1
      end

      it 'has <p:meta-data>/<p:title> tag which contains title' do
        title = xml.xpath('p:meta-data/p:title')
        expect(title.size()).to be 1
        expect(title.first.text).to eq exercise.title
      end

      it 'has single tag <p:proglang version="8">java</p:proglang>' do
        proglangs = xml.xpath('p:proglang')
        expect(proglangs.size()).to be 1


        expect(proglangs.text).to eq 'Java'

        proglang_version = proglangs.first.xpath('@version')
        expect(proglang_version.size()).to be 1
        expect(proglang_version.first.value).to eq '8'
      end

      it 'has empty <p:submission-restrictions>/<p:file-restriction>/<p:optional filename=''> tag' do
        restrictions = xml.xpath('p:submission-restrictions/p:file-restrictions/p:optional')
        expect(restrictions.size()).to be 0
        expect(restrictions.text).to be_empty
      end
    end

    describe 'files' do
      it 'has valid main file' do
        file = xml.xpath('p:files/p:file[@comment="main" and @class="template"]')
        exercise_main_file = exercise.files.where(role: 'main_file').first
        expect(file.size()).to be 1
        expect(file.text).to eq exercise_main_file.content
        expect(file.xpath('@filename').first.value).to eq (exercise_main_file.name + '.java')
      end

      it 'has 4 internal files' do
        files = xml.xpath('p:files/p:file[@class="internal"]')
        expect(files.size()).to be 4
      end

      it 'has one test file referenced by tests' do
        test_ref = xml.xpath('//p:test/p:test-configuration/p:filerefs/p:fileref[1]/@refid').first.value
        test = xml.xpath('p:files/p:file[@filename="test.java"]')
        expect(test_ref.size()).to be 1
        expect(test.size()).to be 1
        expect(test.xpath('@id').first.value).to eq test_ref
        expect(test.text).to eq generator.tests.first.content
      end

      it 'has one reference implementation referenced by model solutions' do
        solution_ref = xml.xpath('//p:model-solution/p:filerefs/p:fileref[1]/@refid').first.value
        solution = xml.xpath('p:files/p:file[@filename="solution.java"]')
        expect(solution_ref.size()).to be 1
        expect(solution.size()).to be 1
        expect(solution.xpath('@id').first.value).to eq solution_ref
        expect(solution.text).to eq generator.model_solution_files.first.content
      end

      it 'has one user defined test' do
        user_test = xml.xpath('p:files/p:file[@filename="user_test.java"]')
        expect(user_test.size()).to be 1
      end

      it 'has one regular file' do
        user_test = xml.xpath('p:files/p:file[@filename="explanation.txt"]')
        expect(user_test.size()).to be 1
      end
    end

    describe 'testing frameworks' do
      it 'returns correct testing framework' do
        xml = generator.generate_xml(exercise)
        framework = generator.testing_framework
        expect(framework.first).to eq 'JUnit'
        expect(framework.second).to eq '4'
      end
    end
  end
end