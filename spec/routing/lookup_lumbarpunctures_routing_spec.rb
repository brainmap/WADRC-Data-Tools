require "spec_helper"

describe LookupLumbarpuncturesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_lumbarpunctures" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_lumbarpunctures/new" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_lumbarpunctures/1" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_lumbarpunctures/1/edit" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_lumbarpunctures" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_lumbarpunctures/1" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_lumbarpunctures/1" }.should route_to(:controller => "lookup_lumbarpunctures", :action => "destroy", :id => "1")
    end

  end
end
