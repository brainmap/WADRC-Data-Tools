require "spec_helper"

describe LookupDrugclassesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_drugclasses" }.should route_to(:controller => "lookup_drugclasses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_drugclasses/new" }.should route_to(:controller => "lookup_drugclasses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_drugclasses/1" }.should route_to(:controller => "lookup_drugclasses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_drugclasses/1/edit" }.should route_to(:controller => "lookup_drugclasses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_drugclasses" }.should route_to(:controller => "lookup_drugclasses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_drugclasses/1" }.should route_to(:controller => "lookup_drugclasses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_drugclasses/1" }.should route_to(:controller => "lookup_drugclasses", :action => "destroy", :id => "1")
    end

  end
end
