require 'spec_helper'

describe "cg_tns/new.html.erb" do
  before(:each) do
    assign(:cg_tn, stub_model(CgTn,
      :tn => "MyString",
      :common_name => "MyString",
      :join_left => "MyString",
      :join_right => "MyString",
      :display_order => 1,
      :table_type => "MyString"
    ).as_new_record)
  end

  it "renders new cg_tn form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cg_tns_path, :method => "post" do
      assert_select "input#cg_tn_tn", :name => "cg_tn[tn]"
      assert_select "input#cg_tn_common_name", :name => "cg_tn[common_name]"
      assert_select "input#cg_tn_join_left", :name => "cg_tn[join_left]"
      assert_select "input#cg_tn_join_right", :name => "cg_tn[join_right]"
      assert_select "input#cg_tn_display_order", :name => "cg_tn[display_order]"
      assert_select "input#cg_tn_table_type", :name => "cg_tn[table_type]"
    end
  end
end
