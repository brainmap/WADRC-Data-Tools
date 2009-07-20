require 'test_helper'

class StudiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:studies)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create study" do
    assert_difference('Study.count') do
      post :create, :study => { }
    end

    assert_redirected_to study_path(assigns(:study))
  end

  test "should show study" do
    get :show, :id => studies(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => studies(:one).id
    assert_response :success
  end

  test "should update study" do
    put :update, :id => studies(:one).id, :study => { }
    assert_redirected_to study_path(assigns(:study))
  end

  test "should destroy study" do
    assert_difference('Study.count', -1) do
      delete :destroy, :id => studies(:one).id
    end

    assert_redirected_to studies_path
  end
end
