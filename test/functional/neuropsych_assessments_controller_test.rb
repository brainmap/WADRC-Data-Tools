require 'test_helper'

class NeuropsychAssessmentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:neuropsych_assessments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create neuropsych_assessment" do
    assert_difference('NeuropsychAssessment.count') do
      post :create, :neuropsych_assessment => { }
    end

    assert_redirected_to neuropsych_assessment_path(assigns(:neuropsych_assessment))
  end

  test "should show neuropsych_assessment" do
    get :show, :id => neuropsych_assessments(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => neuropsych_assessments(:one).id
    assert_response :success
  end

  test "should update neuropsych_assessment" do
    put :update, :id => neuropsych_assessments(:one).id, :neuropsych_assessment => { }
    assert_redirected_to neuropsych_assessment_path(assigns(:neuropsych_assessment))
  end

  test "should destroy neuropsych_assessment" do
    assert_difference('NeuropsychAssessment.count', -1) do
      delete :destroy, :id => neuropsych_assessments(:one).id
    end

    assert_redirected_to neuropsych_assessments_path
  end
end
