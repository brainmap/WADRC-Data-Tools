require "spec_helper"

describe LookupRelationshipsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_relationships" }.should route_to(:controller => "lookup_relationships", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_relationships/new" }.should route_to(:controller => "lookup_relationships", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_relationships/1" }.should route_to(:controller => "lookup_relationships", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_relationships/1/edit" }.should route_to(:controller => "lookup_relationships", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_relationships" }.should route_to(:controller => "lookup_relationships", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_relationships/1" }.should route_to(:controller => "lookup_relationships", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_relationships/1" }.should route_to(:controller => "lookup_relationships", :action => "destroy", :id => "1")
    end

  end
end
