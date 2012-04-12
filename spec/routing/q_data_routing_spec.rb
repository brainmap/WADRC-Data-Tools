require "spec_helper"

describe QDataController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/q_data" }.should route_to(:controller => "q_data", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/q_data/new" }.should route_to(:controller => "q_data", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/q_data/1" }.should route_to(:controller => "q_data", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/q_data/1/edit" }.should route_to(:controller => "q_data", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/q_data" }.should route_to(:controller => "q_data", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/q_data/1" }.should route_to(:controller => "q_data", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/q_data/1" }.should route_to(:controller => "q_data", :action => "destroy", :id => "1")
    end

  end
end
