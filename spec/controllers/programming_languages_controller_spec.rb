require 'rails_helper'

describe ProgrammingLanguagesController do
  let(:execution_environment) { FactoryBot.create(:ruby) }
  let(:user) { FactoryBot.create(:admin) }
  let(:programming_language) {FactoryBot.create(:ruby_2_2)}
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }
  before :each do
    request.headers["accept"] = 'application/json'
  end

  describe 'GET #show' do
    before(:each) {
      get :show, id: programming_language.id
    }
    expect_assigns(programming_language: :programming_language)
    expect_status(200)
    expect_json
  end

  describe 'GET #versions' do
    let(:programming_languages) {ProgrammingLanguage.where(name: programming_language.name)}
    before(:each) {
      get :versions, proglang: programming_language.name
    }
    expect_assigns(programming_languages: :programming_languages)
    expect_status(200)
    expect_json
  end

  describe 'POST #create' do
    context 'with existing programming language' do
      let(:request_proc) { proc { post :create, name: 'Ruby', version: '2.2', is_default: false}}
      before(:each) {
        request_proc.call
      }
      expect_assigns(programming_language: :programming_language)
      expect_status(200)
      expect_json
      it 'should not change count' do
        expect{ request_proc.call }.to change(ProgrammingLanguage, :count).by(0)
      end
    end

    context 'with not existing programming language' do
      let(:request_proc) { proc { post :create, name: 'nonexistent', version: '404', is_default: false}}
      before(:each) {
        request_proc.call
      }

      expect_status(200)
      expect_json

      it 'should change count' do
        proglang = ProgrammingLanguage.find_by(name: 'nonexistent', version: '404')
        proglang.try(:destroy)
        expect{ request_proc.call }.to change(ProgrammingLanguage, :count).by(1)
      end
    end

    context 'with default set as true' do
      context 'should fail for existing default execution environment' do
        let(:request_proc) { proc { post :create, name: 'ruby', version: '2.2', is_default: true}}
        before(:each) {
          request_proc.call
        }
        expect_status(200)
        expect_json
      end

      context 'should pass for non-existing default execution environment' do
        let(:request_proc) { proc { post :create, name: 'nonexistent', version: '404', is_default: true}}
        before(:each) {
          request_proc.call
        }
        expect_status(200)
        expect_json
      end
    end
  end
end