require 'spec_helper'

describe "petscans/edit.html.erb" do
  before(:each) do
    @petscan = assign(:petscan, stub_model(Petscan,
      :appointment_id => 1,
      :lookup_pettracer_id => 1,
      :EcatFilename => "MyString",
      :netinjecteddose => 1.5,
      :units => "MyString",
      :range => "MyString"
    ))
  end

  it "renders the edit petscan form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => petscan_path(@petscan), :method => "post" do
      assert_select "input#petscan_appointment_id", :name => "petscan[appointment_id]"
      assert_select "input#petscan_lookup_pettracer_id", :name => "petscan[lookup_pettracer_id]"
      assert_select "input#petscan_EcatFilename", :name => "petscan[EcatFilename]"
      assert_select "input#petscan_netinjecteddose", :name => "petscan[netinjecteddose]"
      assert_select "input#petscan_units", :name => "petscan[units]"
      assert_select "input#petscan_range", :name => "petscan[range]"
    end
  end
end
