require "spec_helper"

describe LookupEligibilityIneligibilitiesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_eligibility_ineligibilities" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_eligibility_ineligibilities/new" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_eligibility_ineligibilities/1" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_eligibility_ineligibilities/1/edit" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_eligibility_ineligibilities" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_eligibility_ineligibilities/1" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_eligibility_ineligibilities/1" }.should route_to(:controller => "lookup_eligibility_ineligibilities", :action => "destroy", :id => "1")
    end

  end
end
