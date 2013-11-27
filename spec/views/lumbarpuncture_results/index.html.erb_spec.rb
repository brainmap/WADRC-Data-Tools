require 'spec_helper'

describe "lumbarpuncture_results/index.html.erb" do
  before(:each) do
    assign(:lumbarpuncture_results, [
      stub_model(LumbarpunctureResult,
        :lumbarpuncture_id => 1,
        :lookup_lumbarpuncture_id => 1,
        :value => 1,
        :value_string => "Value String"
      ),
      stub_model(LumbarpunctureResult,
        :lumbarpuncture_id => 1,
        :lookup_lumbarpuncture_id => 1,
        :value => 1,
        :value_string => "Value String"
      )
    ])
  end

  it "renders a list of lumbarpuncture_results" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Value String".to_s, :count => 2
  end
end
