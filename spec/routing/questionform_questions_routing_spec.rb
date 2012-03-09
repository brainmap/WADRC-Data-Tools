require "spec_helper"

describe QuestionformQuestionsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/questionform_questions" }.should route_to(:controller => "questionform_questions", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/questionform_questions/new" }.should route_to(:controller => "questionform_questions", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/questionform_questions/1" }.should route_to(:controller => "questionform_questions", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/questionform_questions/1/edit" }.should route_to(:controller => "questionform_questions", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/questionform_questions" }.should route_to(:controller => "questionform_questions", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/questionform_questions/1" }.should route_to(:controller => "questionform_questions", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/questionform_questions/1" }.should route_to(:controller => "questionform_questions", :action => "destroy", :id => "1")
    end

  end
end
