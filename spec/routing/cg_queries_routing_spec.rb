require "spec_helper"

describe CgQueriesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/cg_queries" }.should route_to(:controller => "cg_queries", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/cg_queries/new" }.should route_to(:controller => "cg_queries", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/cg_queries/1" }.should route_to(:controller => "cg_queries", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/cg_queries/1/edit" }.should route_to(:controller => "cg_queries", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/cg_queries" }.should route_to(:controller => "cg_queries", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/cg_queries/1" }.should route_to(:controller => "cg_queries", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/cg_queries/1" }.should route_to(:controller => "cg_queries", :action => "destroy", :id => "1")
    end

  end
end
