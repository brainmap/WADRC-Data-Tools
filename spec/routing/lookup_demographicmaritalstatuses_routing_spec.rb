require "spec_helper"

describe LookupDemographicmaritalstatusesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_demographicmaritalstatuses" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_demographicmaritalstatuses/new" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_demographicmaritalstatuses/1" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_demographicmaritalstatuses/1/edit" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_demographicmaritalstatuses" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_demographicmaritalstatuses/1" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_demographicmaritalstatuses/1" }.should route_to(:controller => "lookup_demographicmaritalstatuses", :action => "destroy", :id => "1")
    end

  end
end
