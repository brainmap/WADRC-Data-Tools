require "spec_helper"

describe LookupDemographicmaritialstatusesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_demographicmaritialstatuses" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_demographicmaritialstatuses/new" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_demographicmaritialstatuses/1" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_demographicmaritialstatuses/1/edit" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_demographicmaritialstatuses" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_demographicmaritialstatuses/1" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_demographicmaritialstatuses/1" }.should route_to(:controller => "lookup_demographicmaritialstatuses", :action => "destroy", :id => "1")
    end

  end
end
