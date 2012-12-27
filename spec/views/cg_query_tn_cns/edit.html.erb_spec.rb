require 'spec_helper'

describe "cg_query_tn_cns/edit.html.erb" do
  before(:each) do
    @cg_query_tn_cn = assign(:cg_query_tn_cn, stub_model(CgQueryTnCn,
      :cg_query_tn_id => 1,
      :cg_tn_cn_id => "",
      :value_1 => "MyString",
      :value_2 => "MyString",
      :condition => 1
    ))
  end

  it "renders the edit cg_query_tn_cn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cg_query_tn_cn_path(@cg_query_tn_cn), :method => "post" do
      assert_select "input#cg_query_tn_cn_cg_query_tn_id", :name => "cg_query_tn_cn[cg_query_tn_id]"
      assert_select "input#cg_query_tn_cn_cg_tn_cn_id", :name => "cg_query_tn_cn[cg_tn_cn_id]"
      assert_select "input#cg_query_tn_cn_value_1", :name => "cg_query_tn_cn[value_1]"
      assert_select "input#cg_query_tn_cn_value_2", :name => "cg_query_tn_cn[value_2]"
      assert_select "input#cg_query_tn_cn_condition", :name => "cg_query_tn_cn[condition]"
    end
  end
end
