require "spec_helper"

describe LookupSwitchboardsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_switchboards" }.should route_to(:controller => "lookup_switchboards", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_switchboards/new" }.should route_to(:controller => "lookup_switchboards", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_switchboards/1" }.should route_to(:controller => "lookup_switchboards", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_switchboards/1/edit" }.should route_to(:controller => "lookup_switchboards", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_switchboards" }.should route_to(:controller => "lookup_switchboards", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_switchboards/1" }.should route_to(:controller => "lookup_switchboards", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_switchboards/1" }.should route_to(:controller => "lookup_switchboards", :action => "destroy", :id => "1")
    end

  end
end
