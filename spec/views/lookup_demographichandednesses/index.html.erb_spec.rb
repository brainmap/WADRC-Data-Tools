require 'spec_helper'

describe "lookup_demographichandednesses/index.html.erb" do
  before(:each) do
    assign(:lookup_demographichandednesses, [
      stub_model(LookupDemographichandedness,
        :description => "Description"
      ),
      stub_model(LookupDemographichandedness,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_demographichandednesses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
