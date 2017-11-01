require 'test_helper'

class ErrorTemplatesControllerTest < ActionController::TestCase
  setup do
    @error_template = error_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:error_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create error_template" do
    assert_difference('ErrorTemplate.count') do
      post :create, error_template: {  }
    end

    assert_redirected_to error_template_path(assigns(:error_template))
  end

  test "should show error_template" do
    get :show, id: @error_template
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @error_template
    assert_response :success
  end

  test "should update error_template" do
    patch :update, id: @error_template, error_template: {  }
    assert_redirected_to error_template_path(assigns(:error_template))
  end

  test "should destroy error_template" do
    assert_difference('ErrorTemplate.count', -1) do
      delete :destroy, id: @error_template
    end

    assert_redirected_to error_templates_path
  end
end
