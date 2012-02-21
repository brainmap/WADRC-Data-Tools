require 'spec_helper'

describe "lookup_hardwares/new.html.erb" do
  before(:each) do
    assign(:lookup_hardware, stub_model(LookupHardware,
      :hardwaretype => "MyString",
      :hardwaregroup => "MyString"
    ).as_new_record)
  end

  it "renders new lookup_hardware form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_hardwares_path, :method => "post" do
      assert_select "input#lookup_hardware_hardwaretype", :name => "lookup_hardware[hardwaretype]"
      assert_select "input#lookup_hardware_hardwaregroup", :name => "lookup_hardware[hardwaregroup]"
    end
  end
end
