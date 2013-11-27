require 'spec_helper'

describe "questionform_questions/index.html.erb" do
  before(:each) do
    assign(:questionform_questions, [
      stub_model(QuestionformQuestion,
        :questionform_id => 1,
        :question_id => 1
      ),
      stub_model(QuestionformQuestion,
        :questionform_id => 1,
        :question_id => 1
      )
    ])
  end

  it "renders a list of questionform_questions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
