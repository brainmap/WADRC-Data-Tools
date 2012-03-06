require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe LookupSwitchboardsController do

  def mock_lookup_switchboard(stubs={})
    @mock_lookup_switchboard ||= mock_model(LookupSwitchboard, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all lookup_switchboards as @lookup_switchboards" do
      LookupSwitchboard.stub(:all) { [mock_lookup_switchboard] }
      get :index
      assigns(:lookup_switchboards).should eq([mock_lookup_switchboard])
    end
  end

  describe "GET show" do
    it "assigns the requested lookup_switchboard as @lookup_switchboard" do
      LookupSwitchboard.stub(:find).with("37") { mock_lookup_switchboard }
      get :show, :id => "37"
      assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
    end
  end

  describe "GET new" do
    it "assigns a new lookup_switchboard as @lookup_switchboard" do
      LookupSwitchboard.stub(:new) { mock_lookup_switchboard }
      get :new
      assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
    end
  end

  describe "GET edit" do
    it "assigns the requested lookup_switchboard as @lookup_switchboard" do
      LookupSwitchboard.stub(:find).with("37") { mock_lookup_switchboard }
      get :edit, :id => "37"
      assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created lookup_switchboard as @lookup_switchboard" do
        LookupSwitchboard.stub(:new).with({'these' => 'params'}) { mock_lookup_switchboard(:save => true) }
        post :create, :lookup_switchboard => {'these' => 'params'}
        assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
      end

      it "redirects to the created lookup_switchboard" do
        LookupSwitchboard.stub(:new) { mock_lookup_switchboard(:save => true) }
        post :create, :lookup_switchboard => {}
        response.should redirect_to(lookup_switchboard_url(mock_lookup_switchboard))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved lookup_switchboard as @lookup_switchboard" do
        LookupSwitchboard.stub(:new).with({'these' => 'params'}) { mock_lookup_switchboard(:save => false) }
        post :create, :lookup_switchboard => {'these' => 'params'}
        assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
      end

      it "re-renders the 'new' template" do
        LookupSwitchboard.stub(:new) { mock_lookup_switchboard(:save => false) }
        post :create, :lookup_switchboard => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested lookup_switchboard" do
        LookupSwitchboard.stub(:find).with("37") { mock_lookup_switchboard }
        mock_lookup_switchboard.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :lookup_switchboard => {'these' => 'params'}
      end

      it "assigns the requested lookup_switchboard as @lookup_switchboard" do
        LookupSwitchboard.stub(:find) { mock_lookup_switchboard(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
      end

      it "redirects to the lookup_switchboard" do
        LookupSwitchboard.stub(:find) { mock_lookup_switchboard(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(lookup_switchboard_url(mock_lookup_switchboard))
      end
    end

    describe "with invalid params" do
      it "assigns the lookup_switchboard as @lookup_switchboard" do
        LookupSwitchboard.stub(:find) { mock_lookup_switchboard(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:lookup_switchboard).should be(mock_lookup_switchboard)
      end

      it "re-renders the 'edit' template" do
        LookupSwitchboard.stub(:find) { mock_lookup_switchboard(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested lookup_switchboard" do
      LookupSwitchboard.stub(:find).with("37") { mock_lookup_switchboard }
      mock_lookup_switchboard.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the lookup_switchboards list" do
      LookupSwitchboard.stub(:find) { mock_lookup_switchboard }
      delete :destroy, :id => "1"
      response.should redirect_to(lookup_switchboards_url)
    end
  end

end