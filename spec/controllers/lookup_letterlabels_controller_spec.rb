require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe LookupLetterlabelsController do

  def mock_lookup_letterlabel(stubs={})
    @mock_lookup_letterlabel ||= mock_model(LookupLetterlabel, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all lookup_letterlabels as @lookup_letterlabels" do
      LookupLetterlabel.stub(:all) { [mock_lookup_letterlabel] }
      get :index
      assigns(:lookup_letterlabels).should eq([mock_lookup_letterlabel])
    end
  end

  describe "GET show" do
    it "assigns the requested lookup_letterlabel as @lookup_letterlabel" do
      LookupLetterlabel.stub(:find).with("37") { mock_lookup_letterlabel }
      get :show, :id => "37"
      assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
    end
  end

  describe "GET new" do
    it "assigns a new lookup_letterlabel as @lookup_letterlabel" do
      LookupLetterlabel.stub(:new) { mock_lookup_letterlabel }
      get :new
      assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
    end
  end

  describe "GET edit" do
    it "assigns the requested lookup_letterlabel as @lookup_letterlabel" do
      LookupLetterlabel.stub(:find).with("37") { mock_lookup_letterlabel }
      get :edit, :id => "37"
      assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created lookup_letterlabel as @lookup_letterlabel" do
        LookupLetterlabel.stub(:new).with({'these' => 'params'}) { mock_lookup_letterlabel(:save => true) }
        post :create, :lookup_letterlabel => {'these' => 'params'}
        assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
      end

      it "redirects to the created lookup_letterlabel" do
        LookupLetterlabel.stub(:new) { mock_lookup_letterlabel(:save => true) }
        post :create, :lookup_letterlabel => {}
        response.should redirect_to(lookup_letterlabel_url(mock_lookup_letterlabel))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved lookup_letterlabel as @lookup_letterlabel" do
        LookupLetterlabel.stub(:new).with({'these' => 'params'}) { mock_lookup_letterlabel(:save => false) }
        post :create, :lookup_letterlabel => {'these' => 'params'}
        assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
      end

      it "re-renders the 'new' template" do
        LookupLetterlabel.stub(:new) { mock_lookup_letterlabel(:save => false) }
        post :create, :lookup_letterlabel => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested lookup_letterlabel" do
        LookupLetterlabel.stub(:find).with("37") { mock_lookup_letterlabel }
        mock_lookup_letterlabel.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :lookup_letterlabel => {'these' => 'params'}
      end

      it "assigns the requested lookup_letterlabel as @lookup_letterlabel" do
        LookupLetterlabel.stub(:find) { mock_lookup_letterlabel(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
      end

      it "redirects to the lookup_letterlabel" do
        LookupLetterlabel.stub(:find) { mock_lookup_letterlabel(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(lookup_letterlabel_url(mock_lookup_letterlabel))
      end
    end

    describe "with invalid params" do
      it "assigns the lookup_letterlabel as @lookup_letterlabel" do
        LookupLetterlabel.stub(:find) { mock_lookup_letterlabel(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:lookup_letterlabel).should be(mock_lookup_letterlabel)
      end

      it "re-renders the 'edit' template" do
        LookupLetterlabel.stub(:find) { mock_lookup_letterlabel(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested lookup_letterlabel" do
      LookupLetterlabel.stub(:find).with("37") { mock_lookup_letterlabel }
      mock_lookup_letterlabel.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the lookup_letterlabels list" do
      LookupLetterlabel.stub(:find) { mock_lookup_letterlabel }
      delete :destroy, :id => "1"
      response.should redirect_to(lookup_letterlabels_url)
    end
  end

end
