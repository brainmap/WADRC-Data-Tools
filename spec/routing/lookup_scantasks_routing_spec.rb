require "spec_helper"

describe LookupScantasksController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_scantasks" }.should route_to(:controller => "lookup_scantasks", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_scantasks/new" }.should route_to(:controller => "lookup_scantasks", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_scantasks/1" }.should route_to(:controller => "lookup_scantasks", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_scantasks/1/edit" }.should route_to(:controller => "lookup_scantasks", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_scantasks" }.should route_to(:controller => "lookup_scantasks", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_scantasks/1" }.should route_to(:controller => "lookup_scantasks", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_scantasks/1" }.should route_to(:controller => "lookup_scantasks", :action => "destroy", :id => "1")
    end

  end
end
