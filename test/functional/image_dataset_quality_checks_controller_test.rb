require 'test_helper'

class ImageDatasetQualityChecksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:image_dataset_quality_checks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create image_dataset_quality_check" do
    assert_difference('ImageDatasetQualityCheck.count') do
      post :create, :image_dataset_quality_check => { }
    end

    assert_redirected_to image_dataset_quality_check_path(assigns(:image_dataset_quality_check))
  end

  test "should show image_dataset_quality_check" do
    get :show, :id => image_dataset_quality_checks(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => image_dataset_quality_checks(:one).id
    assert_response :success
  end

  test "should update image_dataset_quality_check" do
    put :update, :id => image_dataset_quality_checks(:one).id, :image_dataset_quality_check => { }
    assert_redirected_to image_dataset_quality_check_path(assigns(:image_dataset_quality_check))
  end

  test "should destroy image_dataset_quality_check" do
    assert_difference('ImageDatasetQualityCheck.count', -1) do
      delete :destroy, :id => image_dataset_quality_checks(:one).id
    end

    assert_redirected_to image_dataset_quality_checks_path
  end
end
