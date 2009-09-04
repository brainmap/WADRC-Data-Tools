require 'test_helper'

class PhysiologyTextFilesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:physiology_text_files)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create physiology_text_file" do
    assert_difference('PhysiologyTextFile.count') do
      post :create, :physiology_text_file => { }
    end

    assert_redirected_to physiology_text_file_path(assigns(:physiology_text_file))
  end

  test "should show physiology_text_file" do
    get :show, :id => physiology_text_files(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => physiology_text_files(:one).to_param
    assert_response :success
  end

  test "should update physiology_text_file" do
    put :update, :id => physiology_text_files(:one).to_param, :physiology_text_file => { }
    assert_redirected_to physiology_text_file_path(assigns(:physiology_text_file))
  end

  test "should destroy physiology_text_file" do
    assert_difference('PhysiologyTextFile.count', -1) do
      delete :destroy, :id => physiology_text_files(:one).to_param
    end

    assert_redirected_to physiology_text_files_path
  end
end
