require "spec_helper"

describe SchedulesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/schedules" }.should route_to(:controller => "schedules", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/schedules/new" }.should route_to(:controller => "schedules", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/schedules/1" }.should route_to(:controller => "schedules", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/schedules/1/edit" }.should route_to(:controller => "schedules", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/schedules" }.should route_to(:controller => "schedules", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/schedules/1" }.should route_to(:controller => "schedules", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/schedules/1" }.should route_to(:controller => "schedules", :action => "destroy", :id => "1")
    end

  end
end
