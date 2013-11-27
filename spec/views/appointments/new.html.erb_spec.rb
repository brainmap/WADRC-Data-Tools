require 'spec_helper'

describe "appointments/new.html.erb" do
  before(:each) do
    assign(:appointment, stub_model(Appointment,
      :vgroup_id => 1,
      :comment => "MyString",
      :appointment_type => "MyString",
      :employee_id => 1
    ).as_new_record)
  end

  it "renders new appointment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => appointments_path, :method => "post" do
      assert_select "input#appointment_vgroup_id", :name => "appointment[vgroup_id]"
      assert_select "input#appointment_comment", :name => "appointment[comment]"
      assert_select "input#appointment_appointment_type", :name => "appointment[appointment_type]"
      assert_select "input#appointment_employee_id", :name => "appointment[employee_id]"
    end
  end
end
