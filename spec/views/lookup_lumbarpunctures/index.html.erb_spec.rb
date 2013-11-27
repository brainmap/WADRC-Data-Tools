require 'spec_helper'

describe "lookup_lumbarpunctures/index.html.erb" do
  before(:each) do
    assign(:lookup_lumbarpunctures, [
      stub_model(LookupLumbarpuncture,
        :description => "Description",
        :units => "Units",
        :range => "Range"
      ),
      stub_model(LookupLumbarpuncture,
        :description => "Description",
        :units => "Units",
        :range => "Range"
      )
    ])
  end

  it "renders a list of lookup_lumbarpunctures" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Units".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Range".to_s, :count => 2
  end
end
