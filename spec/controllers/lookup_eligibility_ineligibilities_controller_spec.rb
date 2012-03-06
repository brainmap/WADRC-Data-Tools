require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe LookupEligibilityIneligibilitiesController do

  def mock_lookup_eligibility_ineligibility(stubs={})
    @mock_lookup_eligibility_ineligibility ||= mock_model(LookupEligibilityIneligibility, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all lookup_eligibility_ineligibilities as @lookup_eligibility_ineligibilities" do
      LookupEligibilityIneligibility.stub(:all) { [mock_lookup_eligibility_ineligibility] }
      get :index
      assigns(:lookup_eligibility_ineligibilities).should eq([mock_lookup_eligibility_ineligibility])
    end
  end

  describe "GET show" do
    it "assigns the requested lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
      LookupEligibilityIneligibility.stub(:find).with("37") { mock_lookup_eligibility_ineligibility }
      get :show, :id => "37"
      assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
    end
  end

  describe "GET new" do
    it "assigns a new lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
      LookupEligibilityIneligibility.stub(:new) { mock_lookup_eligibility_ineligibility }
      get :new
      assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
    end
  end

  describe "GET edit" do
    it "assigns the requested lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
      LookupEligibilityIneligibility.stub(:find).with("37") { mock_lookup_eligibility_ineligibility }
      get :edit, :id => "37"
      assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:new).with({'these' => 'params'}) { mock_lookup_eligibility_ineligibility(:save => true) }
        post :create, :lookup_eligibility_ineligibility => {'these' => 'params'}
        assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
      end

      it "redirects to the created lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:new) { mock_lookup_eligibility_ineligibility(:save => true) }
        post :create, :lookup_eligibility_ineligibility => {}
        response.should redirect_to(lookup_eligibility_ineligibility_url(mock_lookup_eligibility_ineligibility))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:new).with({'these' => 'params'}) { mock_lookup_eligibility_ineligibility(:save => false) }
        post :create, :lookup_eligibility_ineligibility => {'these' => 'params'}
        assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
      end

      it "re-renders the 'new' template" do
        LookupEligibilityIneligibility.stub(:new) { mock_lookup_eligibility_ineligibility(:save => false) }
        post :create, :lookup_eligibility_ineligibility => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:find).with("37") { mock_lookup_eligibility_ineligibility }
        mock_lookup_eligibility_ineligibility.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :lookup_eligibility_ineligibility => {'these' => 'params'}
      end

      it "assigns the requested lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:find) { mock_lookup_eligibility_ineligibility(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
      end

      it "redirects to the lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:find) { mock_lookup_eligibility_ineligibility(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(lookup_eligibility_ineligibility_url(mock_lookup_eligibility_ineligibility))
      end
    end

    describe "with invalid params" do
      it "assigns the lookup_eligibility_ineligibility as @lookup_eligibility_ineligibility" do
        LookupEligibilityIneligibility.stub(:find) { mock_lookup_eligibility_ineligibility(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:lookup_eligibility_ineligibility).should be(mock_lookup_eligibility_ineligibility)
      end

      it "re-renders the 'edit' template" do
        LookupEligibilityIneligibility.stub(:find) { mock_lookup_eligibility_ineligibility(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested lookup_eligibility_ineligibility" do
      LookupEligibilityIneligibility.stub(:find).with("37") { mock_lookup_eligibility_ineligibility }
      mock_lookup_eligibility_ineligibility.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the lookup_eligibility_ineligibilities list" do
      LookupEligibilityIneligibility.stub(:find) { mock_lookup_eligibility_ineligibility }
      delete :destroy, :id => "1"
      response.should redirect_to(lookup_eligibility_ineligibilities_url)
    end
  end

end