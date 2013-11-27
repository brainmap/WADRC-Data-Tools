require "spec_helper"

describe NeuropsychesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/neuropsyches" }.should route_to(:controller => "neuropsyches", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/neuropsyches/new" }.should route_to(:controller => "neuropsyches", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/neuropsyches/1" }.should route_to(:controller => "neuropsyches", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/neuropsyches/1/edit" }.should route_to(:controller => "neuropsyches", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/neuropsyches" }.should route_to(:controller => "neuropsyches", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/neuropsyches/1" }.should route_to(:controller => "neuropsyches", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/neuropsyches/1" }.should route_to(:controller => "neuropsyches", :action => "destroy", :id => "1")
    end

  end
end
