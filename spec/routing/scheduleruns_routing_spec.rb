require "spec_helper"

describe SchedulerunsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/scheduleruns" }.should route_to(:controller => "scheduleruns", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/scheduleruns/new" }.should route_to(:controller => "scheduleruns", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/scheduleruns/1" }.should route_to(:controller => "scheduleruns", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/scheduleruns/1/edit" }.should route_to(:controller => "scheduleruns", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/scheduleruns" }.should route_to(:controller => "scheduleruns", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/scheduleruns/1" }.should route_to(:controller => "scheduleruns", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/scheduleruns/1" }.should route_to(:controller => "scheduleruns", :action => "destroy", :id => "1")
    end

  end
end
