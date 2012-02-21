require 'spec_helper'

describe "lookup_drugfreqs/index.html.erb" do
  before(:each) do
    assign(:lookup_drugfreqs, [
      stub_model(LookupDrugfreq,
        :frequency => "Frequency",
        :description => "Description"
      ),
      stub_model(LookupDrugfreq,
        :frequency => "Frequency",
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_drugfreqs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Frequency".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
