require 'test_helper'

class ImageDatasetsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:image_datasets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create image_dataset" do
    assert_difference('ImageDataset.count') do
      post :create, :image_dataset => { }
    end

    assert_redirected_to image_dataset_path(assigns(:image_dataset))
  end

  test "should show image_dataset" do
    get :show, :id => image_datasets(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => image_datasets(:one).id
    assert_response :success
  end

  test "should update image_dataset" do
    put :update, :id => image_datasets(:one).id, :image_dataset => { }
    assert_redirected_to image_dataset_path(assigns(:image_dataset))
  end

  test "should destroy image_dataset" do
    assert_difference('ImageDataset.count', -1) do
      delete :destroy, :id => image_datasets(:one).id
    end

    assert_redirected_to image_datasets_path
  end
end
