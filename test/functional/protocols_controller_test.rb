require 'test_helper'

class ProtocolsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:protocols)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_protocol
    assert_difference('Protocol.count') do
      post :create, :protocol => { }
    end

    assert_redirected_to protocol_path(assigns(:protocol))
  end

  def test_should_show_protocol
    get :show, :id => protocols(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => protocols(:one).id
    assert_response :success
  end

  def test_should_update_protocol
    put :update, :id => protocols(:one).id, :protocol => { }
    assert_redirected_to protocol_path(assigns(:protocol))
  end

  def test_should_destroy_protocol
    assert_difference('Protocol.count', -1) do
      delete :destroy, :id => protocols(:one).id
    end

    assert_redirected_to protocols_path
  end
end
