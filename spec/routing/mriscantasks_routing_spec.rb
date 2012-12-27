require "spec_helper"

describe MriscantasksController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/mriscantasks" }.should route_to(:controller => "mriscantasks", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/mriscantasks/new" }.should route_to(:controller => "mriscantasks", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/mriscantasks/1" }.should route_to(:controller => "mriscantasks", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/mriscantasks/1/edit" }.should route_to(:controller => "mriscantasks", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/mriscantasks" }.should route_to(:controller => "mriscantasks", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/mriscantasks/1" }.should route_to(:controller => "mriscantasks", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/mriscantasks/1" }.should route_to(:controller => "mriscantasks", :action => "destroy", :id => "1")
    end

  end
end
