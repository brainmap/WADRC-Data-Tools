require "spec_helper"

describe ProtocolRolesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/protocol_roles" }.should route_to(:controller => "protocol_roles", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/protocol_roles/new" }.should route_to(:controller => "protocol_roles", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/protocol_roles/1" }.should route_to(:controller => "protocol_roles", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/protocol_roles/1/edit" }.should route_to(:controller => "protocol_roles", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/protocol_roles" }.should route_to(:controller => "protocol_roles", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/protocol_roles/1" }.should route_to(:controller => "protocol_roles", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/protocol_roles/1" }.should route_to(:controller => "protocol_roles", :action => "destroy", :id => "1")
    end

  end
end
