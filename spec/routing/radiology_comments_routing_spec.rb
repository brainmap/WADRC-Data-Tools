require "spec_helper"

describe RadiologyCommentsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/radiology_comments" }.should route_to(:controller => "radiology_comments", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/radiology_comments/new" }.should route_to(:controller => "radiology_comments", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/radiology_comments/1" }.should route_to(:controller => "radiology_comments", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/radiology_comments/1/edit" }.should route_to(:controller => "radiology_comments", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/radiology_comments" }.should route_to(:controller => "radiology_comments", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/radiology_comments/1" }.should route_to(:controller => "radiology_comments", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/radiology_comments/1" }.should route_to(:controller => "radiology_comments", :action => "destroy", :id => "1")
    end

  end
end
