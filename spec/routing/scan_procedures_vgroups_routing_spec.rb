require "spec_helper"

describe ScanProceduresVgroupsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/scan_procedures_vgroups" }.should route_to(:controller => "scan_procedures_vgroups", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/scan_procedures_vgroups/new" }.should route_to(:controller => "scan_procedures_vgroups", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/scan_procedures_vgroups/1" }.should route_to(:controller => "scan_procedures_vgroups", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/scan_procedures_vgroups/1/edit" }.should route_to(:controller => "scan_procedures_vgroups", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/scan_procedures_vgroups" }.should route_to(:controller => "scan_procedures_vgroups", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/scan_procedures_vgroups/1" }.should route_to(:controller => "scan_procedures_vgroups", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/scan_procedures_vgroups/1" }.should route_to(:controller => "scan_procedures_vgroups", :action => "destroy", :id => "1")
    end

  end
end
