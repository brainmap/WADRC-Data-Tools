require "spec_helper"

describe MedicationdetailsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/medicationdetails" }.should route_to(:controller => "medicationdetails", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/medicationdetails/new" }.should route_to(:controller => "medicationdetails", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/medicationdetails/1" }.should route_to(:controller => "medicationdetails", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/medicationdetails/1/edit" }.should route_to(:controller => "medicationdetails", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/medicationdetails" }.should route_to(:controller => "medicationdetails", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/medicationdetails/1" }.should route_to(:controller => "medicationdetails", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/medicationdetails/1" }.should route_to(:controller => "medicationdetails", :action => "destroy", :id => "1")
    end

  end
end
