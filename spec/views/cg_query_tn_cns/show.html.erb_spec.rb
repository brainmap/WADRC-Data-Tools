require 'spec_helper'

describe "cg_query_tn_cns/show.html.erb" do
  before(:each) do
    @cg_query_tn_cn = assign(:cg_query_tn_cn, stub_model(CgQueryTnCn,
      :cg_query_tn_id => 1,
      :cg_tn_cn_id => "",
      :value_1 => "Value 1",
      :value_2 => "Value 2",
      :condition => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value 1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value 2/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
