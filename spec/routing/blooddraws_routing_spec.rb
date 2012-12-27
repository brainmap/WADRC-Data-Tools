require "spec_helper"

describe BlooddrawsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/blooddraws" }.should route_to(:controller => "blooddraws", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/blooddraws/new" }.should route_to(:controller => "blooddraws", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/blooddraws/1" }.should route_to(:controller => "blooddraws", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/blooddraws/1/edit" }.should route_to(:controller => "blooddraws", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/blooddraws" }.should route_to(:controller => "blooddraws", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/blooddraws/1" }.should route_to(:controller => "blooddraws", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/blooddraws/1" }.should route_to(:controller => "blooddraws", :action => "destroy", :id => "1")
    end

  end
end
