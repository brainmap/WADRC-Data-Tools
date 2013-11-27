require 'spec_helper'

describe "cg_query_tn_cns/index.html.erb" do
  before(:each) do
    assign(:cg_query_tn_cns, [
      stub_model(CgQueryTnCn,
        :cg_query_tn_id => 1,
        :cg_tn_cn_id => "",
        :value_1 => "Value 1",
        :value_2 => "Value 2",
        :condition => 1
      ),
      stub_model(CgQueryTnCn,
        :cg_query_tn_id => 1,
        :cg_tn_cn_id => "",
        :value_1 => "Value 1",
        :value_2 => "Value 2",
        :condition => 1
      )
    ])
  end

  it "renders a list of cg_query_tn_cns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value 1".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value 2".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
