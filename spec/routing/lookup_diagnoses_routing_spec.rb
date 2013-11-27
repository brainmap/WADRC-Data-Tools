require "spec_helper"

describe LookupDiagnosesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_diagnoses" }.should route_to(:controller => "lookup_diagnoses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_diagnoses/new" }.should route_to(:controller => "lookup_diagnoses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_diagnoses/1" }.should route_to(:controller => "lookup_diagnoses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_diagnoses/1/edit" }.should route_to(:controller => "lookup_diagnoses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_diagnoses" }.should route_to(:controller => "lookup_diagnoses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_diagnoses/1" }.should route_to(:controller => "lookup_diagnoses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_diagnoses/1" }.should route_to(:controller => "lookup_diagnoses", :action => "destroy", :id => "1")
    end

  end
end
