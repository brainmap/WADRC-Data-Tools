require "spec_helper"

describe VgroupsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/vgroups" }.should route_to(:controller => "vgroups", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/vgroups/new" }.should route_to(:controller => "vgroups", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/vgroups/1" }.should route_to(:controller => "vgroups", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/vgroups/1/edit" }.should route_to(:controller => "vgroups", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/vgroups" }.should route_to(:controller => "vgroups", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/vgroups/1" }.should route_to(:controller => "vgroups", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/vgroups/1" }.should route_to(:controller => "vgroups", :action => "destroy", :id => "1")
    end

  end
end
