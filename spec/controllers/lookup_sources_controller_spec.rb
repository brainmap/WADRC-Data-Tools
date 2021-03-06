require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe LookupSourcesController do

  def mock_lookup_source(stubs={})
    @mock_lookup_source ||= mock_model(LookupSource, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all lookup_sources as @lookup_sources" do
      LookupSource.stub(:all) { [mock_lookup_source] }
      get :index
      assigns(:lookup_sources).should eq([mock_lookup_source])
    end
  end

  describe "GET show" do
    it "assigns the requested lookup_source as @lookup_source" do
      LookupSource.stub(:find).with("37") { mock_lookup_source }
      get :show, :id => "37"
      assigns(:lookup_source).should be(mock_lookup_source)
    end
  end

  describe "GET new" do
    it "assigns a new lookup_source as @lookup_source" do
      LookupSource.stub(:new) { mock_lookup_source }
      get :new
      assigns(:lookup_source).should be(mock_lookup_source)
    end
  end

  describe "GET edit" do
    it "assigns the requested lookup_source as @lookup_source" do
      LookupSource.stub(:find).with("37") { mock_lookup_source }
      get :edit, :id => "37"
      assigns(:lookup_source).should be(mock_lookup_source)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created lookup_source as @lookup_source" do
        LookupSource.stub(:new).with({'these' => 'params'}) { mock_lookup_source(:save => true) }
        post :create, :lookup_source => {'these' => 'params'}
        assigns(:lookup_source).should be(mock_lookup_source)
      end

      it "redirects to the created lookup_source" do
        LookupSource.stub(:new) { mock_lookup_source(:save => true) }
        post :create, :lookup_source => {}
        response.should redirect_to(lookup_source_url(mock_lookup_source))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved lookup_source as @lookup_source" do
        LookupSource.stub(:new).with({'these' => 'params'}) { mock_lookup_source(:save => false) }
        post :create, :lookup_source => {'these' => 'params'}
        assigns(:lookup_source).should be(mock_lookup_source)
      end

      it "re-renders the 'new' template" do
        LookupSource.stub(:new) { mock_lookup_source(:save => false) }
        post :create, :lookup_source => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested lookup_source" do
        LookupSource.stub(:find).with("37") { mock_lookup_source }
        mock_lookup_source.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :lookup_source => {'these' => 'params'}
      end

      it "assigns the requested lookup_source as @lookup_source" do
        LookupSource.stub(:find) { mock_lookup_source(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:lookup_source).should be(mock_lookup_source)
      end

      it "redirects to the lookup_source" do
        LookupSource.stub(:find) { mock_lookup_source(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(lookup_source_url(mock_lookup_source))
      end
    end

    describe "with invalid params" do
      it "assigns the lookup_source as @lookup_source" do
        LookupSource.stub(:find) { mock_lookup_source(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:lookup_source).should be(mock_lookup_source)
      end

      it "re-renders the 'edit' template" do
        LookupSource.stub(:find) { mock_lookup_source(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested lookup_source" do
      LookupSource.stub(:find).with("37") { mock_lookup_source }
      mock_lookup_source.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the lookup_sources list" do
      LookupSource.stub(:find) { mock_lookup_source }
      delete :destroy, :id => "1"
      response.should redirect_to(lookup_sources_url)
    end
  end

end
