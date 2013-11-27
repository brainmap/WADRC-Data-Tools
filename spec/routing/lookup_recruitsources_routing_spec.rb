require "spec_helper"

describe LookupRecruitsourcesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_recruitsources" }.should route_to(:controller => "lookup_recruitsources", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_recruitsources/new" }.should route_to(:controller => "lookup_recruitsources", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_recruitsources/1" }.should route_to(:controller => "lookup_recruitsources", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_recruitsources/1/edit" }.should route_to(:controller => "lookup_recruitsources", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_recruitsources" }.should route_to(:controller => "lookup_recruitsources", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_recruitsources/1" }.should route_to(:controller => "lookup_recruitsources", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_recruitsources/1" }.should route_to(:controller => "lookup_recruitsources", :action => "destroy", :id => "1")
    end

  end
end
