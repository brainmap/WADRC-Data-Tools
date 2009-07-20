require 'test_helper'

class NeuropsychSessionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:neuropsych_sessions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create neuropsych_session" do
    assert_difference('NeuropsychSession.count') do
      post :create, :neuropsych_session => { }
    end

    assert_redirected_to neuropsych_session_path(assigns(:neuropsych_session))
  end

  test "should show neuropsych_session" do
    get :show, :id => neuropsych_sessions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => neuropsych_sessions(:one).id
    assert_response :success
  end

  test "should update neuropsych_session" do
    put :update, :id => neuropsych_sessions(:one).id, :neuropsych_session => { }
    assert_redirected_to neuropsych_session_path(assigns(:neuropsych_session))
  end

  test "should destroy neuropsych_session" do
    assert_difference('NeuropsychSession.count', -1) do
      delete :destroy, :id => neuropsych_sessions(:one).id
    end

    assert_redirected_to neuropsych_sessions_path
  end
end
