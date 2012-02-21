require "spec_helper"

describe LookupDemographicincomesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_demographicincomes" }.should route_to(:controller => "lookup_demographicincomes", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_demographicincomes/new" }.should route_to(:controller => "lookup_demographicincomes", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_demographicincomes/1" }.should route_to(:controller => "lookup_demographicincomes", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_demographicincomes/1/edit" }.should route_to(:controller => "lookup_demographicincomes", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_demographicincomes" }.should route_to(:controller => "lookup_demographicincomes", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_demographicincomes/1" }.should route_to(:controller => "lookup_demographicincomes", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_demographicincomes/1" }.should route_to(:controller => "lookup_demographicincomes", :action => "destroy", :id => "1")
    end

  end
end
