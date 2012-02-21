require "spec_helper"

describe LookupStatusesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_statuses" }.should route_to(:controller => "lookup_statuses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_statuses/new" }.should route_to(:controller => "lookup_statuses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_statuses/1" }.should route_to(:controller => "lookup_statuses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_statuses/1/edit" }.should route_to(:controller => "lookup_statuses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_statuses" }.should route_to(:controller => "lookup_statuses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_statuses/1" }.should route_to(:controller => "lookup_statuses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_statuses/1" }.should route_to(:controller => "lookup_statuses", :action => "destroy", :id => "1")
    end

  end
end
