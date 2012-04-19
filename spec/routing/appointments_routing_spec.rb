require "spec_helper"

describe AppointmentsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/appointments" }.should route_to(:controller => "appointments", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/appointments/new" }.should route_to(:controller => "appointments", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/appointments/1" }.should route_to(:controller => "appointments", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/appointments/1/edit" }.should route_to(:controller => "appointments", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/appointments" }.should route_to(:controller => "appointments", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/appointments/1" }.should route_to(:controller => "appointments", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/appointments/1" }.should route_to(:controller => "appointments", :action => "destroy", :id => "1")
    end

  end
end
