require "spec_helper"

describe QDataFormsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/q_data_forms" }.should route_to(:controller => "q_data_forms", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/q_data_forms/new" }.should route_to(:controller => "q_data_forms", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/q_data_forms/1" }.should route_to(:controller => "q_data_forms", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/q_data_forms/1/edit" }.should route_to(:controller => "q_data_forms", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/q_data_forms" }.should route_to(:controller => "q_data_forms", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/q_data_forms/1" }.should route_to(:controller => "q_data_forms", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/q_data_forms/1" }.should route_to(:controller => "q_data_forms", :action => "destroy", :id => "1")
    end

  end
end
