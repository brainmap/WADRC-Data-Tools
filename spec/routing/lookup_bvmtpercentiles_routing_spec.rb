require "spec_helper"

describe LookupBvmtpercentilesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_bvmtpercentiles" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_bvmtpercentiles/new" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_bvmtpercentiles/1" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_bvmtpercentiles/1/edit" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_bvmtpercentiles" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_bvmtpercentiles/1" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_bvmtpercentiles/1" }.should route_to(:controller => "lookup_bvmtpercentiles", :action => "destroy", :id => "1")
    end

  end
end
