require "spec_helper"

describe LookupDrugfreqsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_drugfreqs" }.should route_to(:controller => "lookup_drugfreqs", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_drugfreqs/new" }.should route_to(:controller => "lookup_drugfreqs", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_drugfreqs/1" }.should route_to(:controller => "lookup_drugfreqs", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_drugfreqs/1/edit" }.should route_to(:controller => "lookup_drugfreqs", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_drugfreqs" }.should route_to(:controller => "lookup_drugfreqs", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_drugfreqs/1" }.should route_to(:controller => "lookup_drugfreqs", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_drugfreqs/1" }.should route_to(:controller => "lookup_drugfreqs", :action => "destroy", :id => "1")
    end

  end
end
