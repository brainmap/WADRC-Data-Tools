require 'spec_helper'

describe "cg_tn_cns/index.html.erb" do
  before(:each) do
    assign(:cg_tn_cns, [
      stub_model(CgTnCn,
        :cn_tn_id => 1,
        :cn => "Cn",
        :common_name => "Common Name",
        :export_name => "Export Name",
        :key_column_flag => "Key Column Flag",
        :ref_table_a => "Ref Table A",
        :ref_table_b => "Ref Table B",
        :data_type => "Data Type",
        :display_order => 1,
        :searchable_flag => "Searchable Flag",
        :value_limits => "Value Limits"
      ),
      stub_model(CgTnCn,
        :cn_tn_id => 1,
        :cn => "Cn",
        :common_name => "Common Name",
        :export_name => "Export Name",
        :key_column_flag => "Key Column Flag",
        :ref_table_a => "Ref Table A",
        :ref_table_b => "Ref Table B",
        :data_type => "Data Type",
        :display_order => 1,
        :searchable_flag => "Searchable Flag",
        :value_limits => "Value Limits"
      )
    ])
  end

  it "renders a list of cg_tn_cns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Cn".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Common Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Export Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Key Column Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table A".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Ref Table B".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Data Type".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Searchable Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value Limits".to_s, :count => 2
  end
end
