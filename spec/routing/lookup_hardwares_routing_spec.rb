require "spec_helper"

describe LookupHardwaresController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_hardwares" }.should route_to(:controller => "lookup_hardwares", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_hardwares/new" }.should route_to(:controller => "lookup_hardwares", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_hardwares/1" }.should route_to(:controller => "lookup_hardwares", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_hardwares/1/edit" }.should route_to(:controller => "lookup_hardwares", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_hardwares" }.should route_to(:controller => "lookup_hardwares", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_hardwares/1" }.should route_to(:controller => "lookup_hardwares", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_hardwares/1" }.should route_to(:controller => "lookup_hardwares", :action => "destroy", :id => "1")
    end

  end
end
