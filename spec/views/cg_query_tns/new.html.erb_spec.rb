require 'spec_helper'

describe "cg_query_tns/new.html.erb" do
  before(:each) do
    assign(:cg_query_tn, stub_model(CgQueryTn,
      :cg_query_id => 1,
      :cg_tn_id => 1,
      :join_type => 1
    ).as_new_record)
  end

  it "renders new cg_query_tn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cg_query_tns_path, :method => "post" do
      assert_select "input#cg_query_tn_cg_query_id", :name => "cg_query_tn[cg_query_id]"
      assert_select "input#cg_query_tn_cg_tn_id", :name => "cg_query_tn[cg_tn_id]"
      assert_select "input#cg_query_tn_join_type", :name => "cg_query_tn[join_type]"
    end
  end
end
