require "spec_helper"

describe LookupEligibilityoutcomesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_eligibilityoutcomes" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_eligibilityoutcomes/new" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_eligibilityoutcomes/1" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_eligibilityoutcomes/1/edit" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_eligibilityoutcomes" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_eligibilityoutcomes/1" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_eligibilityoutcomes/1" }.should route_to(:controller => "lookup_eligibilityoutcomes", :action => "destroy", :id => "1")
    end

  end
end
