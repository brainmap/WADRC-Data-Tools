require 'spec_helper'

describe "q_data_forms/show.html.erb" do
  before(:each) do
    @q_data_form = assign(:q_data_form, stub_model(QDataForm,
      :questionform_id => 1,
      :participant_id => 1,
      :visit_id => 1,
      :appointment_id => 1,
      :protocol_id => 1,
      :enrollment_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
