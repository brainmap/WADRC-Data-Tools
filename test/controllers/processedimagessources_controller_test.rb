require 'test_helper'

class ProcessedimagessourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @processedimagessource = processedimagessources(:one)
  end

  test "should get index" do
    get processedimagessources_url
    assert_response :success
  end

  test "should get new" do
    get new_processedimagessource_url
    assert_response :success
  end

  test "should create processedimagessource" do
    assert_difference('Processedimagessource.count') do
      post processedimagessources_url, params: { processedimagessource: { comment: @processedimagessource.comment, file_name: @processedimagessource.file_name, file_path: @processedimagessource.file_path, processedimage_id: @processedimagessource.processedimage_id, source_image_id: @processedimagessource.source_image_id, source_image_type: @processedimagessource.source_image_type } }
    end

    assert_redirected_to processedimagessource_url(Processedimagessource.last)
  end

  test "should show processedimagessource" do
    get processedimagessource_url(@processedimagessource)
    assert_response :success
  end

  test "should get edit" do
    get edit_processedimagessource_url(@processedimagessource)
    assert_response :success
  end

  test "should update processedimagessource" do
    patch processedimagessource_url(@processedimagessource), params: { processedimagessource: { comment: @processedimagessource.comment, file_name: @processedimagessource.file_name, file_path: @processedimagessource.file_path, processedimage_id: @processedimagessource.processedimage_id, source_image_id: @processedimagessource.source_image_id, source_image_type: @processedimagessource.source_image_type } }
    assert_redirected_to processedimagessource_url(@processedimagessource)
  end

  test "should destroy processedimagessource" do
    assert_difference('Processedimagessource.count', -1) do
      delete processedimagessource_url(@processedimagessource)
    end

    assert_redirected_to processedimagessources_url
  end
end
