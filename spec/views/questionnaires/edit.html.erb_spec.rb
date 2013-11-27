require 'spec_helper'

describe "questionnaires/edit.html.erb" do
  before(:each) do
    @questionnaire = assign(:questionnaire, stub_model(Questionnaire,
      :appointment_id => 1
    ))
  end

  it "renders the edit questionnaire form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionnaire_path(@questionnaire), :method => "post" do
      assert_select "input#questionnaire_appointment_id", :name => "questionnaire[appointment_id]"
    end
  end
end
