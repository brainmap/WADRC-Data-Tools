require 'spec_helper'

describe "cg_tn_cns/new.html.erb" do
  before(:each) do
    assign(:cg_tn_cn, stub_model(CgTnCn,
      :cn_tn_id => 1,
      :cn => "MyString",
      :common_name => "MyString",
      :export_name => "MyString",
      :key_column_flag => "MyString",
      :ref_table_a => "MyString",
      :ref_table_b => "MyString",
      :data_type => "MyString",
      :display_order => 1,
      :searchable_flag => "MyString",
      :value_limits => "MyString"
    ).as_new_record)
  end

  it "renders new cg_tn_cn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cg_tn_cns_path, :method => "post" do
      assert_select "input#cg_tn_cn_cn_tn_id", :name => "cg_tn_cn[cn_tn_id]"
      assert_select "input#cg_tn_cn_cn", :name => "cg_tn_cn[cn]"
      assert_select "input#cg_tn_cn_common_name", :name => "cg_tn_cn[common_name]"
      assert_select "input#cg_tn_cn_export_name", :name => "cg_tn_cn[export_name]"
      assert_select "input#cg_tn_cn_key_column_flag", :name => "cg_tn_cn[key_column_flag]"
      assert_select "input#cg_tn_cn_ref_table_a", :name => "cg_tn_cn[ref_table_a]"
      assert_select "input#cg_tn_cn_ref_table_b", :name => "cg_tn_cn[ref_table_b]"
      assert_select "input#cg_tn_cn_data_type", :name => "cg_tn_cn[data_type]"
      assert_select "input#cg_tn_cn_display_order", :name => "cg_tn_cn[display_order]"
      assert_select "input#cg_tn_cn_searchable_flag", :name => "cg_tn_cn[searchable_flag]"
      assert_select "input#cg_tn_cn_value_limits", :name => "cg_tn_cn[value_limits]"
    end
  end
end
