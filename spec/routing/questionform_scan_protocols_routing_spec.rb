require "spec_helper"

describe QuestionformScanProtocolsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/questionform_scan_protocols" }.should route_to(:controller => "questionform_scan_protocols", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/questionform_scan_protocols/new" }.should route_to(:controller => "questionform_scan_protocols", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/questionform_scan_protocols/1" }.should route_to(:controller => "questionform_scan_protocols", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/questionform_scan_protocols/1/edit" }.should route_to(:controller => "questionform_scan_protocols", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/questionform_scan_protocols" }.should route_to(:controller => "questionform_scan_protocols", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/questionform_scan_protocols/1" }.should route_to(:controller => "questionform_scan_protocols", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/questionform_scan_protocols/1" }.should route_to(:controller => "questionform_scan_protocols", :action => "destroy", :id => "1")
    end

  end
end
