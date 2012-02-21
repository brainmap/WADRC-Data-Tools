require "spec_helper"

describe LookupImagingplanesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/lookup_imagingplanes" }.should route_to(:controller => "lookup_imagingplanes", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/lookup_imagingplanes/new" }.should route_to(:controller => "lookup_imagingplanes", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/lookup_imagingplanes/1" }.should route_to(:controller => "lookup_imagingplanes", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/lookup_imagingplanes/1/edit" }.should route_to(:controller => "lookup_imagingplanes", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/lookup_imagingplanes" }.should route_to(:controller => "lookup_imagingplanes", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/lookup_imagingplanes/1" }.should route_to(:controller => "lookup_imagingplanes", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/lookup_imagingplanes/1" }.should route_to(:controller => "lookup_imagingplanes", :action => "destroy", :id => "1")
    end

  end
end
