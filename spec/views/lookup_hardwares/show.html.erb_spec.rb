require 'spec_helper'

describe "lookup_hardwares/show.html.erb" do
  before(:each) do
    @lookup_hardware = assign(:lookup_hardware, stub_model(LookupHardware,
      :hardwaretype => "Hardwaretype",
      :hardwaregroup => "Hardwaregroup"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Hardwaretype/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Hardwaregroup/)
  end
end
