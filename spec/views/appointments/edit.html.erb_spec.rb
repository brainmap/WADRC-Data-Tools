require 'spec_helper'

describe "appointments/edit.html.erb" do
  before(:each) do
    @appointment = assign(:appointment, stub_model(Appointment,
      :vgroup_id => 1,
      :comment => "MyString",
      :appointment_type => "MyString",
      :employee_id => 1
    ))
  end

  it "renders the edit appointment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => appointment_path(@appointment), :method => "post" do
      assert_select "input#appointment_vgroup_id", :name => "appointment[vgroup_id]"
      assert_select "input#appointment_comment", :name => "appointment[comment]"
      assert_select "input#appointment_appointment_type", :name => "appointment[appointment_type]"
      assert_select "input#appointment_employee_id", :name => "appointment[employee_id]"
    end
  end
end
