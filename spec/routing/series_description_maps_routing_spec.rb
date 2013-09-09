require "spec_helper"

describe SeriesDescriptionMapsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/series_description_maps" }.should route_to(:controller => "series_description_maps", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/series_description_maps/new" }.should route_to(:controller => "series_description_maps", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/series_description_maps/1" }.should route_to(:controller => "series_description_maps", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/series_description_maps/1/edit" }.should route_to(:controller => "series_description_maps", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/series_description_maps" }.should route_to(:controller => "series_description_maps", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/series_description_maps/1" }.should route_to(:controller => "series_description_maps", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/series_description_maps/1" }.should route_to(:controller => "series_description_maps", :action => "destroy", :id => "1")
    end

  end
end
