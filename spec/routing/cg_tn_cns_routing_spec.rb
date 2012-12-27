require "spec_helper"

describe CgTnCnsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/cg_tn_cns" }.should route_to(:controller => "cg_tn_cns", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/cg_tn_cns/new" }.should route_to(:controller => "cg_tn_cns", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/cg_tn_cns/1" }.should route_to(:controller => "cg_tn_cns", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/cg_tn_cns/1/edit" }.should route_to(:controller => "cg_tn_cns", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/cg_tn_cns" }.should route_to(:controller => "cg_tn_cns", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/cg_tn_cns/1" }.should route_to(:controller => "cg_tn_cns", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/cg_tn_cns/1" }.should route_to(:controller => "cg_tn_cns", :action => "destroy", :id => "1")
    end

  end
end
