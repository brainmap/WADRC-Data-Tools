require "spec_helper"

describe LookupGendersController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_genders" }.should route_to(:controller => "lookup_genders", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_genders/new" }.should route_to(:controller => "lookup_genders", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_genders/1" }.should route_to(:controller => "lookup_genders", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_genders/1/edit" }.should route_to(:controller => "lookup_genders", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_genders" }.should route_to(:controller => "lookup_genders", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_genders/1" }.should route_to(:controller => "lookup_genders", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_genders/1" }.should route_to(:controller => "lookup_genders", :action => "destroy", :id => "1")
    end

  end
end
