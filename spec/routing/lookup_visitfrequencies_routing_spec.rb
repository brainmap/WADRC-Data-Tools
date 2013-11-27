require "spec_helper"

describe LookupVisitfrequenciesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_visitfrequencies" }.should route_to(:controller => "lookup_visitfrequencies", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_visitfrequencies/new" }.should route_to(:controller => "lookup_visitfrequencies", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_visitfrequencies/1" }.should route_to(:controller => "lookup_visitfrequencies", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_visitfrequencies/1/edit" }.should route_to(:controller => "lookup_visitfrequencies", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_visitfrequencies" }.should route_to(:controller => "lookup_visitfrequencies", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_visitfrequencies/1" }.should route_to(:controller => "lookup_visitfrequencies", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_visitfrequencies/1" }.should route_to(:controller => "lookup_visitfrequencies", :action => "destroy", :id => "1")
    end

  end
end
