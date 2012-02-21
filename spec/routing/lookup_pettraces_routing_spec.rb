require "spec_helper"

describe LookupPettracesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_pettraces" }.should route_to(:controller => "lookup_pettraces", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_pettraces/new" }.should route_to(:controller => "lookup_pettraces", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_pettraces/1" }.should route_to(:controller => "lookup_pettraces", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_pettraces/1/edit" }.should route_to(:controller => "lookup_pettraces", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_pettraces" }.should route_to(:controller => "lookup_pettraces", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_pettraces/1" }.should route_to(:controller => "lookup_pettraces", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_pettraces/1" }.should route_to(:controller => "lookup_pettraces", :action => "destroy", :id => "1")
    end

  end
end
