require 'rails_helper'

describe 'Authorization' do
  context 'as an admin' do
    let(:user) { FactoryBot.create(:admin) }
    before(:each) { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user) }

    [Consumer, ExecutionEnvironment, Exercise, FileType, InternalUser].each do |model|
      expect_permitted_path(:"new_#{model.model_name.singular}_path")
    end
  end

  context 'as an external user' do
    let(:user) { FactoryBot.create(:external_user) }
    before(:each) { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user) }

    [Consumer, ExecutionEnvironment, Exercise, FileType, InternalUser].each do |model|
      expect_forbidden_path(:"new_#{model.model_name.singular}_path")
    end
  end

  context 'as a teacher' do
    let(:user) { FactoryBot.create(:teacher) }
    before(:each) { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user) }

    [Consumer, InternalUser].each do |model|
      expect_forbidden_path(:"new_#{model.model_name.singular}_path")
    end

    [ExecutionEnvironment, Exercise, FileType].each do |model|
      expect_permitted_path(:"new_#{model.model_name.singular}_path")
    end
  end
end
