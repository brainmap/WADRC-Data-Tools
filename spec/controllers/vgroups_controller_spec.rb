require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by the Rails when you ran the scaffold generator.

describe VgroupsController do

  def mock_vgroup(stubs={})
    @mock_vgroup ||= mock_model(Vgroup, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all vgroups as @vgroups" do
      Vgroup.stub(:all) { [mock_vgroup] }
      get :index
      assigns(:vgroups).should eq([mock_vgroup])
    end
  end

  describe "GET show" do
    it "assigns the requested vgroup as @vgroup" do
      Vgroup.stub(:find).with("37") { mock_vgroup }
      get :show, :id => "37"
      assigns(:vgroup).should be(mock_vgroup)
    end
  end

  describe "GET new" do
    it "assigns a new vgroup as @vgroup" do
      Vgroup.stub(:new) { mock_vgroup }
      get :new
      assigns(:vgroup).should be(mock_vgroup)
    end
  end

  describe "GET edit" do
    it "assigns the requested vgroup as @vgroup" do
      Vgroup.stub(:find).with("37") { mock_vgroup }
      get :edit, :id => "37"
      assigns(:vgroup).should be(mock_vgroup)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created vgroup as @vgroup" do
        Vgroup.stub(:new).with({'these' => 'params'}) { mock_vgroup(:save => true) }
        post :create, :vgroup => {'these' => 'params'}
        assigns(:vgroup).should be(mock_vgroup)
      end

      it "redirects to the created vgroup" do
        Vgroup.stub(:new) { mock_vgroup(:save => true) }
        post :create, :vgroup => {}
        response.should redirect_to(vgroup_url(mock_vgroup))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved vgroup as @vgroup" do
        Vgroup.stub(:new).with({'these' => 'params'}) { mock_vgroup(:save => false) }
        post :create, :vgroup => {'these' => 'params'}
        assigns(:vgroup).should be(mock_vgroup)
      end

      it "re-renders the 'new' template" do
        Vgroup.stub(:new) { mock_vgroup(:save => false) }
        post :create, :vgroup => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested vgroup" do
        Vgroup.stub(:find).with("37") { mock_vgroup }
        mock_vgroup.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :vgroup => {'these' => 'params'}
      end

      it "assigns the requested vgroup as @vgroup" do
        Vgroup.stub(:find) { mock_vgroup(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:vgroup).should be(mock_vgroup)
      end

      it "redirects to the vgroup" do
        Vgroup.stub(:find) { mock_vgroup(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(vgroup_url(mock_vgroup))
      end
    end

    describe "with invalid params" do
      it "assigns the vgroup as @vgroup" do
        Vgroup.stub(:find) { mock_vgroup(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:vgroup).should be(mock_vgroup)
      end

      it "re-renders the 'edit' template" do
        Vgroup.stub(:find) { mock_vgroup(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested vgroup" do
      Vgroup.stub(:find).with("37") { mock_vgroup }
      mock_vgroup.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the vgroups list" do
      Vgroup.stub(:find) { mock_vgroup }
      delete :destroy, :id => "1"
      response.should redirect_to(vgroups_url)
    end
  end

end
