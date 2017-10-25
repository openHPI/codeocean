require 'test_helper'

class ErrorTemplateAttributesControllerTest < ActionController::TestCase
  setup do
    @error_template_attribute = error_template_attributes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:error_template_attributes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create error_template_attribute" do
    assert_difference('ErrorTemplateAttribute.count') do
      post :create, error_template_attribute: {  }
    end

    assert_redirected_to error_template_attribute_path(assigns(:error_template_attribute))
  end

  test "should show error_template_attribute" do
    get :show, id: @error_template_attribute
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @error_template_attribute
    assert_response :success
  end

  test "should update error_template_attribute" do
    patch :update, id: @error_template_attribute, error_template_attribute: {  }
    assert_redirected_to error_template_attribute_path(assigns(:error_template_attribute))
  end

  test "should destroy error_template_attribute" do
    assert_difference('ErrorTemplateAttribute.count', -1) do
      delete :destroy, id: @error_template_attribute
    end

    assert_redirected_to error_template_attributes_path
  end
end
