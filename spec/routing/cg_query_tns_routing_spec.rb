require "spec_helper"

describe CgQueryTnsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/cg_query_tns" }.should route_to(:controller => "cg_query_tns", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/cg_query_tns/new" }.should route_to(:controller => "cg_query_tns", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/cg_query_tns/1" }.should route_to(:controller => "cg_query_tns", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/cg_query_tns/1/edit" }.should route_to(:controller => "cg_query_tns", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/cg_query_tns" }.should route_to(:controller => "cg_query_tns", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/cg_query_tns/1" }.should route_to(:controller => "cg_query_tns", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/cg_query_tns/1" }.should route_to(:controller => "cg_query_tns", :action => "destroy", :id => "1")
    end

  end
end
