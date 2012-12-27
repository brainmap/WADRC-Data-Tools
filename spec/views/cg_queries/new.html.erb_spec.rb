require 'spec_helper'

describe "cg_queries/new.html.erb" do
  before(:each) do
    assign(:cg_query, stub_model(CgQuery,
      :user_id => 1,
      :save_flag => "MyString",
      :encumber => "MyString",
      :save_flag => "MyString",
      :rmr => "MyString",
      :scan_procedure_id_list => "MyString",
      :cg_name => "MyString",
      :gender => 1,
      :min_age => 1,
      :max_age => 1
    ).as_new_record)
  end

  it "renders new cg_query form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => cg_queries_path, :method => "post" do
      assert_select "input#cg_query_user_id", :name => "cg_query[user_id]"
      assert_select "input#cg_query_save_flag", :name => "cg_query[save_flag]"
      assert_select "input#cg_query_encumber", :name => "cg_query[encumber]"
      assert_select "input#cg_query_save_flag", :name => "cg_query[save_flag]"
      assert_select "input#cg_query_rmr", :name => "cg_query[rmr]"
      assert_select "input#cg_query_scan_procedure_id_list", :name => "cg_query[scan_procedure_id_list]"
      assert_select "input#cg_query_cg_name", :name => "cg_query[cg_name]"
      assert_select "input#cg_query_gender", :name => "cg_query[gender]"
      assert_select "input#cg_query_min_age", :name => "cg_query[min_age]"
      assert_select "input#cg_query_max_age", :name => "cg_query[max_age]"
    end
  end
end
