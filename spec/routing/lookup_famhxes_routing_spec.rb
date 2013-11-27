require "spec_helper"

describe LookupFamhxesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_famhxes" }.should route_to(:controller => "lookup_famhxes", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_famhxes/new" }.should route_to(:controller => "lookup_famhxes", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_famhxes/1" }.should route_to(:controller => "lookup_famhxes", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_famhxes/1/edit" }.should route_to(:controller => "lookup_famhxes", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_famhxes" }.should route_to(:controller => "lookup_famhxes", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_famhxes/1" }.should route_to(:controller => "lookup_famhxes", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_famhxes/1" }.should route_to(:controller => "lookup_famhxes", :action => "destroy", :id => "1")
    end

  end
end
