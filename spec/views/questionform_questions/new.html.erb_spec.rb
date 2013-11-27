require 'spec_helper'

describe "questionform_questions/new.html.erb" do
  before(:each) do
    assign(:questionform_question, stub_model(QuestionformQuestion,
      :questionform_id => 1,
      :question_id => 1
    ).as_new_record)
  end

  it "renders new questionform_question form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionform_questions_path, :method => "post" do
      assert_select "input#questionform_question_questionform_id", :name => "questionform_question[questionform_id]"
      assert_select "input#questionform_question_question_id", :name => "questionform_question[question_id]"
    end
  end
end
