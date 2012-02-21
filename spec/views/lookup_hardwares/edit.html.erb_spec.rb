require 'spec_helper'

describe "lookup_hardwares/edit.html.erb" do
  before(:each) do
    @lookup_hardware = assign(:lookup_hardware, stub_model(LookupHardware,
      :hardwaretype => "MyString",
      :hardwaregroup => "MyString"
    ))
  end

  it "renders the edit lookup_hardware form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_hardware_path(@lookup_hardware), :method => "post" do
      assert_select "input#lookup_hardware_hardwaretype", :name => "lookup_hardware[hardwaretype]"
      assert_select "input#lookup_hardware_hardwaregroup", :name => "lookup_hardware[hardwaregroup]"
    end
  end
end
