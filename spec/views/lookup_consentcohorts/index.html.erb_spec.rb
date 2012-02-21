require 'spec_helper'

describe "lookup_consentcohorts/index.html.erb" do
  before(:each) do
    assign(:lookup_consentcohorts, [
      stub_model(LookupConsentcohort,
        :description => "Description"
      ),
      stub_model(LookupConsentcohort,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_consentcohorts" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
