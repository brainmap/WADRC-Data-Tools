require 'test_helper'

class SeriesDescriptionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:series_descriptions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create series_description" do
    assert_difference('SeriesDescription.count') do
      post :create, :series_description => { }
    end

    assert_redirected_to series_description_path(assigns(:series_description))
  end

  test "should show series_description" do
    get :show, :id => series_descriptions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => series_descriptions(:one).id
    assert_response :success
  end

  test "should update series_description" do
    put :update, :id => series_descriptions(:one).id, :series_description => { }
    assert_redirected_to series_description_path(assigns(:series_description))
  end

  test "should destroy series_description" do
    assert_difference('SeriesDescription.count', -1) do
      delete :destroy, :id => series_descriptions(:one).id
    end

    assert_redirected_to series_descriptions_path
  end
end
