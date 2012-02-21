require "spec_helper"

describe LookupSourcesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_sources" }.should route_to(:controller => "lookup_sources", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_sources/new" }.should route_to(:controller => "lookup_sources", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_sources/1" }.should route_to(:controller => "lookup_sources", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_sources/1/edit" }.should route_to(:controller => "lookup_sources", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_sources" }.should route_to(:controller => "lookup_sources", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_sources/1" }.should route_to(:controller => "lookup_sources", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_sources/1" }.should route_to(:controller => "lookup_sources", :action => "destroy", :id => "1")
    end

  end
end
