require "spec_helper"

describe LookupDrugunitsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_drugunits" }.should route_to(:controller => "lookup_drugunits", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_drugunits/new" }.should route_to(:controller => "lookup_drugunits", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_drugunits/1" }.should route_to(:controller => "lookup_drugunits", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_drugunits/1/edit" }.should route_to(:controller => "lookup_drugunits", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_drugunits" }.should route_to(:controller => "lookup_drugunits", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_drugunits/1" }.should route_to(:controller => "lookup_drugunits", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_drugunits/1" }.should route_to(:controller => "lookup_drugunits", :action => "destroy", :id => "1")
    end

  end
end
