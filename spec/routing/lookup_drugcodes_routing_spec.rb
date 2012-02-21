require "spec_helper"

describe LookupDrugcodesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_drugcodes" }.should route_to(:controller => "lookup_drugcodes", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_drugcodes/new" }.should route_to(:controller => "lookup_drugcodes", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_drugcodes/1" }.should route_to(:controller => "lookup_drugcodes", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_drugcodes/1/edit" }.should route_to(:controller => "lookup_drugcodes", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_drugcodes" }.should route_to(:controller => "lookup_drugcodes", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_drugcodes/1" }.should route_to(:controller => "lookup_drugcodes", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_drugcodes/1" }.should route_to(:controller => "lookup_drugcodes", :action => "destroy", :id => "1")
    end

  end
end
