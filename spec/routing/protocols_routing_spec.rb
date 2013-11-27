require "spec_helper"

describe ProtocolsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/protocols" }.should route_to(:controller => "protocols", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/protocols/new" }.should route_to(:controller => "protocols", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/protocols/1" }.should route_to(:controller => "protocols", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/protocols/1/edit" }.should route_to(:controller => "protocols", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/protocols" }.should route_to(:controller => "protocols", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/protocols/1" }.should route_to(:controller => "protocols", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/protocols/1" }.should route_to(:controller => "protocols", :action => "destroy", :id => "1")
    end

  end
end
