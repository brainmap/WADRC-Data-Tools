require 'spec_helper'

describe "cg_queries/index.html.erb" do
  before(:each) do
    assign(:cg_queries, [
      stub_model(CgQuery,
        :user_id => 1,
        :save_flag => "Save Flag",
        :encumber => "Encumber",
        :save_flag => "Save Flag",
        :rmr => "Rmr",
        :scan_procedure_id_list => "Scan Procedure Id List",
        :cg_name => "Cg Name",
        :gender => 1,
        :min_age => 1,
        :max_age => 1
      ),
      stub_model(CgQuery,
        :user_id => 1,
        :save_flag => "Save Flag",
        :encumber => "Encumber",
        :save_flag => "Save Flag",
        :rmr => "Rmr",
        :scan_procedure_id_list => "Scan Procedure Id List",
        :cg_name => "Cg Name",
        :gender => 1,
        :min_age => 1,
        :max_age => 1
      )
    ])
  end

  it "renders a list of cg_queries" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Save Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Encumber".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Save Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Rmr".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Scan Procedure Id List".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Cg Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
