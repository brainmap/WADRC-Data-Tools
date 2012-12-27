require 'spec_helper'

describe "questionnaires/new.html.erb" do
  before(:each) do
    assign(:questionnaire, stub_model(Questionnaire,
      :appointment_id => 1
    ).as_new_record)
  end

  it "renders new questionnaire form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => questionnaires_path, :method => "post" do
      assert_select "input#questionnaire_appointment_id", :name => "questionnaire[appointment_id]"
    end
  end
end
