require 'spec_helper'

describe "questionform_questions/edit.html.erb" do
  before(:each) do
    @questionform_question = assign(:questionform_question, stub_model(QuestionformQuestion,
      :questionform_id => 1,
      :question_id => 1
    ))
  end

  it "renders the edit questionform_question form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionform_question_path(@questionform_question), :method => "post" do
      assert_select "input#questionform_question_questionform_id", :name => "questionform_question[questionform_id]"
      assert_select "input#questionform_question_question_id", :name => "questionform_question[question_id]"
    end
  end
end
