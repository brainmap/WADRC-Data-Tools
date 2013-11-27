require "spec_helper"

describe LookupCohortsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_cohorts" }.should route_to(:controller => "lookup_cohorts", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_cohorts/new" }.should route_to(:controller => "lookup_cohorts", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_cohorts/1" }.should route_to(:controller => "lookup_cohorts", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_cohorts/1/edit" }.should route_to(:controller => "lookup_cohorts", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_cohorts" }.should route_to(:controller => "lookup_cohorts", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_cohorts/1" }.should route_to(:controller => "lookup_cohorts", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_cohorts/1" }.should route_to(:controller => "lookup_cohorts", :action => "destroy", :id => "1")
    end

  end
end
