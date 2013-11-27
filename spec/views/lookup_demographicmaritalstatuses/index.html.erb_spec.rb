require 'spec_helper'

describe "lookup_demographicmaritalstatuses/index.html.erb" do
  before(:each) do
    assign(:lookup_demographicmaritalstatuses, [
      stub_model(LookupDemographicmaritalstatus,
        :description => "Description"
      ),
      stub_model(LookupDemographicmaritalstatus,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_demographicmaritalstatuses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
