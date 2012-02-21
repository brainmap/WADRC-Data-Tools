require "spec_helper"

describe LookupConsentcohortsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_consentcohorts" }.should route_to(:controller => "lookup_consentcohorts", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_consentcohorts/new" }.should route_to(:controller => "lookup_consentcohorts", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_consentcohorts/1" }.should route_to(:controller => "lookup_consentcohorts", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_consentcohorts/1/edit" }.should route_to(:controller => "lookup_consentcohorts", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_consentcohorts" }.should route_to(:controller => "lookup_consentcohorts", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_consentcohorts/1" }.should route_to(:controller => "lookup_consentcohorts", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_consentcohorts/1" }.should route_to(:controller => "lookup_consentcohorts", :action => "destroy", :id => "1")
    end

  end
end
