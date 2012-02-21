require "spec_helper"

describe LookupEthnicitiesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_ethnicities" }.should route_to(:controller => "lookup_ethnicities", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_ethnicities/new" }.should route_to(:controller => "lookup_ethnicities", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_ethnicities/1" }.should route_to(:controller => "lookup_ethnicities", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_ethnicities/1/edit" }.should route_to(:controller => "lookup_ethnicities", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_ethnicities" }.should route_to(:controller => "lookup_ethnicities", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_ethnicities/1" }.should route_to(:controller => "lookup_ethnicities", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_ethnicities/1" }.should route_to(:controller => "lookup_ethnicities", :action => "destroy", :id => "1")
    end

  end
end
