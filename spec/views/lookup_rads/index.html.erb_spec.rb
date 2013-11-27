require 'spec_helper'

describe "lookup_rads/index.html.erb" do
  before(:each) do
    assign(:lookup_rads, [
      stub_model(LookupRad,
        :description => "Description"
      ),
      stub_model(LookupRad,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_rads" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
