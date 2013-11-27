require 'spec_helper'

describe "cg_tns/show.html.erb" do
  before(:each) do
    @cg_tn = assign(:cg_tn, stub_model(CgTn,
      :tn => "Tn",
      :common_name => "Common Name",
      :join_left => "Join Left",
      :join_right => "Join Right",
      :display_order => 1,
      :table_type => "Table Type"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Tn/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Common Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Join Left/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Join Right/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Table Type/)
  end
end
