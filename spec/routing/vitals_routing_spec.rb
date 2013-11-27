require "spec_helper"

describe VitalsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/vitals" }.should route_to(:controller => "vitals", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/vitals/new" }.should route_to(:controller => "vitals", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/vitals/1" }.should route_to(:controller => "vitals", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/vitals/1/edit" }.should route_to(:controller => "vitals", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/vitals" }.should route_to(:controller => "vitals", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/vitals/1" }.should route_to(:controller => "vitals", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/vitals/1" }.should route_to(:controller => "vitals", :action => "destroy", :id => "1")
    end

  end
end
