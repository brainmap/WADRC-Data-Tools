require 'test_helper'

class WithdrawlsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:withdrawls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create withdrawl" do
    assert_difference('Withdrawl.count') do
      post :create, :withdrawl => { }
    end

    assert_redirected_to withdrawl_path(assigns(:withdrawl))
  end

  test "should show withdrawl" do
    get :show, :id => withdrawls(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => withdrawls(:one).id
    assert_response :success
  end

  test "should update withdrawl" do
    put :update, :id => withdrawls(:one).id, :withdrawl => { }
    assert_redirected_to withdrawl_path(assigns(:withdrawl))
  end

  test "should destroy withdrawl" do
    assert_difference('Withdrawl.count', -1) do
      delete :destroy, :id => withdrawls(:one).id
    end

    assert_redirected_to withdrawls_path
  end
end
