require 'spec_helper'

describe "lookup_consentforms/index.html.erb" do
  before(:each) do
    assign(:lookup_consentforms, [
      stub_model(LookupConsentform,
        :description => "Description"
      ),
      stub_model(LookupConsentform,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_consentforms" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
