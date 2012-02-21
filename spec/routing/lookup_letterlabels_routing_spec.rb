require "spec_helper"

describe LookupLetterlabelsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_letterlabels" }.should route_to(:controller => "lookup_letterlabels", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_letterlabels/new" }.should route_to(:controller => "lookup_letterlabels", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_letterlabels/1" }.should route_to(:controller => "lookup_letterlabels", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_letterlabels/1/edit" }.should route_to(:controller => "lookup_letterlabels", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_letterlabels" }.should route_to(:controller => "lookup_letterlabels", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_letterlabels/1" }.should route_to(:controller => "lookup_letterlabels", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_letterlabels/1" }.should route_to(:controller => "lookup_letterlabels", :action => "destroy", :id => "1")
    end

  end
end
