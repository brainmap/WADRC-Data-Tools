require 'test_helper'

class HelpsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:helps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create help" do
    assert_difference('Help.count') do
      post :create, :help => { }
    end

    assert_redirected_to help_path(assigns(:help))
  end

  test "should show help" do
    get :show, :id => helps(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => helps(:one).to_param
    assert_response :success
  end

  test "should update help" do
    put :update, :id => helps(:one).to_param, :help => { }
    assert_redirected_to help_path(assigns(:help))
  end

  test "should destroy help" do
    assert_difference('Help.count', -1) do
      delete :destroy, :id => helps(:one).to_param
    end

    assert_redirected_to helps_path
  end
end
