require 'spec_helper'

describe "lookup_switchboards/index.html.erb" do
  before(:each) do
    assign(:lookup_switchboards, [
      stub_model(LookupSwitchboard,
        :description => "Description",
        :item_number => 1,
        :command => "Command",
        :argument => "Argument"
      ),
      stub_model(LookupSwitchboard,
        :description => "Description",
        :item_number => 1,
        :command => "Command",
        :argument => "Argument"
      )
    ])
  end

  it "renders a list of lookup_switchboards" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Command".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Argument".to_s, :count => 2
  end
end
