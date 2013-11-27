require "spec_helper"

describe MriperformancesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/mriperformances" }.should route_to(:controller => "mriperformances", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/mriperformances/new" }.should route_to(:controller => "mriperformances", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/mriperformances/1" }.should route_to(:controller => "mriperformances", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/mriperformances/1/edit" }.should route_to(:controller => "mriperformances", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/mriperformances" }.should route_to(:controller => "mriperformances", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/mriperformances/1" }.should route_to(:controller => "mriperformances", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/mriperformances/1" }.should route_to(:controller => "mriperformances", :action => "destroy", :id => "1")
    end

  end
end
