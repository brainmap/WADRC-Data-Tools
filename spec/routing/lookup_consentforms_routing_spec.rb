require "spec_helper"

describe LookupConsentformsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_consentforms" }.should route_to(:controller => "lookup_consentforms", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_consentforms/new" }.should route_to(:controller => "lookup_consentforms", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_consentforms/1" }.should route_to(:controller => "lookup_consentforms", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_consentforms/1/edit" }.should route_to(:controller => "lookup_consentforms", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_consentforms" }.should route_to(:controller => "lookup_consentforms", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_consentforms/1" }.should route_to(:controller => "lookup_consentforms", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_consentforms/1" }.should route_to(:controller => "lookup_consentforms", :action => "destroy", :id => "1")
    end

  end
end
