require "spec_helper"

describe QuestionScanProtocolsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/question_scan_protocols" }.should route_to(:controller => "question_scan_protocols", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/question_scan_protocols/new" }.should route_to(:controller => "question_scan_protocols", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/question_scan_protocols/1" }.should route_to(:controller => "question_scan_protocols", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/question_scan_protocols/1/edit" }.should route_to(:controller => "question_scan_protocols", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/question_scan_protocols" }.should route_to(:controller => "question_scan_protocols", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/question_scan_protocols/1" }.should route_to(:controller => "question_scan_protocols", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/question_scan_protocols/1" }.should route_to(:controller => "question_scan_protocols", :action => "destroy", :id => "1")
    end

  end
end
