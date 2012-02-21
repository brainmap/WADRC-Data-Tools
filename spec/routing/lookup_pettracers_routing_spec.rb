require "spec_helper"

describe LookupPettracersController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_pettracers" }.should route_to(:controller => "lookup_pettracers", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_pettracers/new" }.should route_to(:controller => "lookup_pettracers", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_pettracers/1" }.should route_to(:controller => "lookup_pettracers", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_pettracers/1/edit" }.should route_to(:controller => "lookup_pettracers", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_pettracers" }.should route_to(:controller => "lookup_pettracers", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_pettracers/1" }.should route_to(:controller => "lookup_pettracers", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_pettracers/1" }.should route_to(:controller => "lookup_pettracers", :action => "destroy", :id => "1")
    end

  end
end
