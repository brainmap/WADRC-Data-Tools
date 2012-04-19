require "spec_helper"

describe PetscansController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/petscans" }.should route_to(:controller => "petscans", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/petscans/new" }.should route_to(:controller => "petscans", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/petscans/1" }.should route_to(:controller => "petscans", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/petscans/1/edit" }.should route_to(:controller => "petscans", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/petscans" }.should route_to(:controller => "petscans", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/petscans/1" }.should route_to(:controller => "petscans", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/petscans/1" }.should route_to(:controller => "petscans", :action => "destroy", :id => "1")
    end

  end
end
