require "spec_helper"

describe QuestionformsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/questionforms" }.should route_to(:controller => "questionforms", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/questionforms/new" }.should route_to(:controller => "questionforms", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/questionforms/1" }.should route_to(:controller => "questionforms", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/questionforms/1/edit" }.should route_to(:controller => "questionforms", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/questionforms" }.should route_to(:controller => "questionforms", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/questionforms/1" }.should route_to(:controller => "questionforms", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/questionforms/1" }.should route_to(:controller => "questionforms", :action => "destroy", :id => "1")
    end

  end
end
