require 'spec_helper'

describe "questionnaires/show.html.erb" do
  before(:each) do
    @questionnaire = assign(:questionnaire, stub_model(Questionnaire,
      :appointment_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
