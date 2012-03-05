require "spec_helper"

describe LookupRefsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_refs" }.should route_to(:controller => "lookup_refs", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_refs/new" }.should route_to(:controller => "lookup_refs", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_refs/1" }.should route_to(:controller => "lookup_refs", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_refs/1/edit" }.should route_to(:controller => "lookup_refs", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_refs" }.should route_to(:controller => "lookup_refs", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_refs/1" }.should route_to(:controller => "lookup_refs", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_refs/1" }.should route_to(:controller => "lookup_refs", :action => "destroy", :id => "1")
    end

  end
end
