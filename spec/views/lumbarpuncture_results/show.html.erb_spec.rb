require 'spec_helper'

describe "lumbarpuncture_results/show.html.erb" do
  before(:each) do
    @lumbarpuncture_result = assign(:lumbarpuncture_result, stub_model(LumbarpunctureResult,
      :lumbarpuncture_id => 1,
      :lookup_lumbarpuncture_id => 1,
      :value => 1,
      :value_string => "Value String"
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
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Value String/)
  end
end
