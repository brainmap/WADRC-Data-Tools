require 'spec_helper'

describe "lookup_hardwares/index.html.erb" do
  before(:each) do
    assign(:lookup_hardwares, [
      stub_model(LookupHardware,
        :hardwaretype => "Hardwaretype",
        :hardwaregroup => "Hardwaregroup"
      ),
      stub_model(LookupHardware,
        :hardwaretype => "Hardwaretype",
        :hardwaregroup => "Hardwaregroup"
      )
    ])
  end

  it "renders a list of lookup_hardwares" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Hardwaretype".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Hardwaregroup".to_s, :count => 2
  end
end
