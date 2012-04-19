require "spec_helper"

describe LumbarpuncturesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lumbarpunctures" }.should route_to(:controller => "lumbarpunctures", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lumbarpunctures/new" }.should route_to(:controller => "lumbarpunctures", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lumbarpunctures/1" }.should route_to(:controller => "lumbarpunctures", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lumbarpunctures/1/edit" }.should route_to(:controller => "lumbarpunctures", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lumbarpunctures" }.should route_to(:controller => "lumbarpunctures", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lumbarpunctures/1" }.should route_to(:controller => "lumbarpunctures", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lumbarpunctures/1" }.should route_to(:controller => "lumbarpunctures", :action => "destroy", :id => "1")
    end

  end
end
