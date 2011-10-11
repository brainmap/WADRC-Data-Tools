require "spec_helper"

describe InvitesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/invites" }.should route_to(:controller => "invites", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/invites/new" }.should route_to(:controller => "invites", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/invites/1" }.should route_to(:controller => "invites", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/invites/1/edit" }.should route_to(:controller => "invites", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/invites" }.should route_to(:controller => "invites", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/invites/1" }.should route_to(:controller => "invites", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/invites/1" }.should route_to(:controller => "invites", :action => "destroy", :id => "1")
    end

  end
end
