require 'spec_helper'

describe "q_data_forms/edit.html.erb" do
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

  it "renders the edit q_data_form form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => q_data_form_path(@q_data_form), :method => "post" do
      assert_select "input#q_data_form_questionform_id", :name => "q_data_form[questionform_id]"
      assert_select "input#q_data_form_participant_id", :name => "q_data_form[participant_id]"
      assert_select "input#q_data_form_visit_id", :name => "q_data_form[visit_id]"
      assert_select "input#q_data_form_appointment_id", :name => "q_data_form[appointment_id]"
      assert_select "input#q_data_form_protocol_id", :name => "q_data_form[protocol_id]"
      assert_select "input#q_data_form_enrollment_id", :name => "q_data_form[enrollment_id]"
    end
  end
end
