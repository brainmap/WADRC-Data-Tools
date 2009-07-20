require 'test_helper'

class RecruitmentGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:recruitment_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create recruitment_group" do
    assert_difference('RecruitmentGroup.count') do
      post :create, :recruitment_group => { }
    end

    assert_redirected_to recruitment_group_path(assigns(:recruitment_group))
  end

  test "should show recruitment_group" do
    get :show, :id => recruitment_groups(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => recruitment_groups(:one).id
    assert_response :success
  end

  test "should update recruitment_group" do
    put :update, :id => recruitment_groups(:one).id, :recruitment_group => { }
    assert_redirected_to recruitment_group_path(assigns(:recruitment_group))
  end

  test "should destroy recruitment_group" do
    assert_difference('RecruitmentGroup.count', -1) do
      delete :destroy, :id => recruitment_groups(:one).id
    end

    assert_redirected_to recruitment_groups_path
  end
end
