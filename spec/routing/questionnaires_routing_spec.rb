require "spec_helper"

describe QuestionnairesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/questionnaires" }.should route_to(:controller => "questionnaires", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/questionnaires/new" }.should route_to(:controller => "questionnaires", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/questionnaires/1" }.should route_to(:controller => "questionnaires", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/questionnaires/1/edit" }.should route_to(:controller => "questionnaires", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/questionnaires" }.should route_to(:controller => "questionnaires", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/questionnaires/1" }.should route_to(:controller => "questionnaires", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/questionnaires/1" }.should route_to(:controller => "questionnaires", :action => "destroy", :id => "1")
    end

  end
end
