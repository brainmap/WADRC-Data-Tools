require 'spec_helper'

describe "vitals/new.html.erb" do
  before(:each) do
    assign(:vital, stub_model(Vital,
      :appointment_id => 1,
      :bp_systol => 1,
      :bp_diastol => 1,
      :pulse => 1,
      :bloodglucose => 1
    ).as_new_record)
  end

  it "renders new vital form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => vitals_path, :method => "post" do
      assert_select "input#vital_appointment_id", :name => "vital[appointment_id]"
      assert_select "input#vital_bp_systol", :name => "vital[bp_systol]"
      assert_select "input#vital_bp_diastol", :name => "vital[bp_diastol]"
      assert_select "input#vital_pulse", :name => "vital[pulse]"
      assert_select "input#vital_bloodglucose", :name => "vital[bloodglucose]"
    end
  end
end
