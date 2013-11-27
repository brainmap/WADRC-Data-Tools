require 'spec_helper'

describe "cg_tns/index.html.erb" do
  before(:each) do
    assign(:cg_tns, [
      stub_model(CgTn,
        :tn => "Tn",
        :common_name => "Common Name",
        :join_left => "Join Left",
        :join_right => "Join Right",
        :display_order => 1,
        :table_type => "Table Type"
      ),
      stub_model(CgTn,
        :tn => "Tn",
        :common_name => "Common Name",
        :join_left => "Join Left",
        :join_right => "Join Right",
        :display_order => 1,
        :table_type => "Table Type"
      )
    ])
  end

  it "renders a list of cg_tns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Tn".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Common Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Join Left".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Join Right".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Table Type".to_s, :count => 2
  end
end
