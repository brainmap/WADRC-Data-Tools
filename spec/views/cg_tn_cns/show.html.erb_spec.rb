require 'spec_helper'

describe "cg_tn_cns/show.html.erb" do
  before(:each) do
    @cg_tn_cn = assign(:cg_tn_cn, stub_model(CgTnCn,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Cn/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Common Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Export Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Key Column Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table A/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Ref Table B/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Data Type/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Searchable Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value Limits/)
  end
end
