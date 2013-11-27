require 'spec_helper'

describe "lookup_demographicincomes/index.html.erb" do
  before(:each) do
    assign(:lookup_demographicincomes, [
      stub_model(LookupDemographicincome,
        :description => "Description"
      ),
      stub_model(LookupDemographicincome,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_demographicincomes" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
