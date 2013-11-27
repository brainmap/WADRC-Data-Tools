require "spec_helper"

describe LumbarpunctureResultsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lumbarpuncture_results" }.should route_to(:controller => "lumbarpuncture_results", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lumbarpuncture_results/new" }.should route_to(:controller => "lumbarpuncture_results", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lumbarpuncture_results/1" }.should route_to(:controller => "lumbarpuncture_results", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lumbarpuncture_results/1/edit" }.should route_to(:controller => "lumbarpuncture_results", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lumbarpuncture_results" }.should route_to(:controller => "lumbarpuncture_results", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lumbarpuncture_results/1" }.should route_to(:controller => "lumbarpuncture_results", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lumbarpuncture_results/1" }.should route_to(:controller => "lumbarpuncture_results", :action => "destroy", :id => "1")
    end

  end
end
