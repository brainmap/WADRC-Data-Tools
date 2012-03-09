require 'spec_helper'

describe "questionform_questions/show.html.erb" do
  before(:each) do
    @questionform_question = assign(:questionform_question, stub_model(QuestionformQuestion,
      :questionform_id => 1,
      :question_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
