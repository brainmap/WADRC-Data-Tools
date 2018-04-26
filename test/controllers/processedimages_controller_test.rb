require 'test_helper'

class ProcessedimagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @processedimage = processedimages(:one)
  end

  test "should get index" do
    get processedimages_url
    assert_response :success
  end

  test "should get new" do
    get new_processedimage_url
    assert_response :success
  end

  test "should create processedimage" do
    assert_difference('Processedimage.count') do
      post processedimages_url, params: { processedimage: { comment: @processedimage.comment, file_name: @processedimage.file_name, file_path: @processedimage.file_path } }
    end

    assert_redirected_to processedimage_url(Processedimage.last)
  end

  test "should show processedimage" do
    get processedimage_url(@processedimage)
    assert_response :success
  end

  test "should get edit" do
    get edit_processedimage_url(@processedimage)
    assert_response :success
  end

  test "should update processedimage" do
    patch processedimage_url(@processedimage), params: { processedimage: { comment: @processedimage.comment, file_name: @processedimage.file_name, file_path: @processedimage.file_path } }
    assert_redirected_to processedimage_url(@processedimage)
  end

  test "should destroy processedimage" do
    assert_difference('Processedimage.count', -1) do
      delete processedimage_url(@processedimage)
    end

    assert_redirected_to processedimages_url
  end
end
