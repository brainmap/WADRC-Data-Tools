require "spec_helper"

describe QuestionScanProceduresController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/question_scan_procedures" }.should route_to(:controller => "question_scan_procedures", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/question_scan_procedures/new" }.should route_to(:controller => "question_scan_procedures", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/question_scan_procedures/1" }.should route_to(:controller => "question_scan_procedures", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/question_scan_procedures/1/edit" }.should route_to(:controller => "question_scan_procedures", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/question_scan_procedures" }.should route_to(:controller => "question_scan_procedures", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/question_scan_procedures/1" }.should route_to(:controller => "question_scan_procedures", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/question_scan_procedures/1" }.should route_to(:controller => "question_scan_procedures", :action => "destroy", :id => "1")
    end

  end
end
