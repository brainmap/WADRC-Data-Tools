require 'spec_helper'

describe "lookup_eligibility_ineligibilities/index.html.erb" do
  before(:each) do
    assign(:lookup_eligibility_ineligibilities, [
      stub_model(LookupEligibilityIneligibility,
        :description => "Description"
      ),
      stub_model(LookupEligibilityIneligibility,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_eligibility_ineligibilities" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
