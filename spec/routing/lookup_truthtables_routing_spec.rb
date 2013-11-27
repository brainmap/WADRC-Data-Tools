require "spec_helper"

describe LookupTruthtablesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_truthtables" }.should route_to(:controller => "lookup_truthtables", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_truthtables/new" }.should route_to(:controller => "lookup_truthtables", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_truthtables/1" }.should route_to(:controller => "lookup_truthtables", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_truthtables/1/edit" }.should route_to(:controller => "lookup_truthtables", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_truthtables" }.should route_to(:controller => "lookup_truthtables", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_truthtables/1" }.should route_to(:controller => "lookup_truthtables", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_truthtables/1" }.should route_to(:controller => "lookup_truthtables", :action => "destroy", :id => "1")
    end

  end
end
