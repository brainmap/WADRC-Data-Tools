require 'spec_helper'

describe "cg_query_tns/index.html.erb" do
  before(:each) do
    assign(:cg_query_tns, [
      stub_model(CgQueryTn,
        :cg_query_id => 1,
        :cg_tn_id => 1,
        :join_type => 1
      ),
      stub_model(CgQueryTn,
        :cg_query_id => 1,
        :cg_tn_id => 1,
        :join_type => 1
      )
    ])
  end

  it "renders a list of cg_query_tns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
