require 'spec_helper'

describe "cg_query_tns/show.html.erb" do
  before(:each) do
    @cg_query_tn = assign(:cg_query_tn, stub_model(CgQueryTn,
      :cg_query_id => 1,
      :cg_tn_id => 1,
      :join_type => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
