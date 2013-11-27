require "spec_helper"

describe LookupDemographicrelativerelationshipsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_demographicrelativerelationships" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_demographicrelativerelationships/new" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_demographicrelativerelationships/1" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_demographicrelativerelationships/1/edit" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_demographicrelativerelationships" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_demographicrelativerelationships/1" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_demographicrelativerelationships/1" }.should route_to(:controller => "lookup_demographicrelativerelationships", :action => "destroy", :id => "1")
    end

  end
end
