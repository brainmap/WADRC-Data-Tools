require "spec_helper"

describe LookupDemographichandednessesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_demographichandednesses" }.should route_to(:controller => "lookup_demographichandednesses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_demographichandednesses/new" }.should route_to(:controller => "lookup_demographichandednesses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_demographichandednesses/1" }.should route_to(:controller => "lookup_demographichandednesses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_demographichandednesses/1/edit" }.should route_to(:controller => "lookup_demographichandednesses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_demographichandednesses" }.should route_to(:controller => "lookup_demographichandednesses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_demographichandednesses/1" }.should route_to(:controller => "lookup_demographichandednesses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_demographichandednesses/1" }.should route_to(:controller => "lookup_demographichandednesses", :action => "destroy", :id => "1")
    end

  end
end
