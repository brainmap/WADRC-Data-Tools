require "spec_helper"

describe LookupCogstatusesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_cogstatuses" }.should route_to(:controller => "lookup_cogstatuses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_cogstatuses/new" }.should route_to(:controller => "lookup_cogstatuses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_cogstatuses/1" }.should route_to(:controller => "lookup_cogstatuses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_cogstatuses/1/edit" }.should route_to(:controller => "lookup_cogstatuses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_cogstatuses" }.should route_to(:controller => "lookup_cogstatuses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_cogstatuses/1" }.should route_to(:controller => "lookup_cogstatuses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_cogstatuses/1" }.should route_to(:controller => "lookup_cogstatuses", :action => "destroy", :id => "1")
    end

  end
end
