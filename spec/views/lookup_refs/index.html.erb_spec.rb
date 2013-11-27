require 'spec_helper'

describe "lookup_refs/index.html.erb" do
  before(:each) do
    assign(:lookup_refs, [
      stub_model(LookupRef,
        :ref_value => 1,
        :description => "Description",
        :display_order => 1,
        :label => "Label"
      ),
      stub_model(LookupRef,
        :ref_value => 1,
        :description => "Description",
        :display_order => 1,
        :label => "Label"
      )
    ])
  end

  it "renders a list of lookup_refs" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Label".to_s, :count => 2
  end
end
