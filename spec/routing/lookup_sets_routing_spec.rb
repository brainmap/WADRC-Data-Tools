require "spec_helper"

describe LookupSetsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_sets" }.should route_to(:controller => "lookup_sets", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_sets/new" }.should route_to(:controller => "lookup_sets", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_sets/1" }.should route_to(:controller => "lookup_sets", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_sets/1/edit" }.should route_to(:controller => "lookup_sets", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_sets" }.should route_to(:controller => "lookup_sets", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_sets/1" }.should route_to(:controller => "lookup_sets", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_sets/1" }.should route_to(:controller => "lookup_sets", :action => "destroy", :id => "1")
    end

  end
end
