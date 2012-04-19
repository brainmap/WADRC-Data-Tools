require 'spec_helper'

describe "lumbarpuncture_results/edit.html.erb" do
  before(:each) do
    @lumbarpuncture_result = assign(:lumbarpuncture_result, stub_model(LumbarpunctureResult,
      :lumbarpuncture_id => 1,
      :lookup_lumbarpuncture_id => 1,
      :value => 1,
      :value_string => "MyString"
    ))
  end

  it "renders the edit lumbarpuncture_result form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lumbarpuncture_result_path(@lumbarpuncture_result), :method => "post" do
      assert_select "input#lumbarpuncture_result_lumbarpuncture_id", :name => "lumbarpuncture_result[lumbarpuncture_id]"
      assert_select "input#lumbarpuncture_result_lookup_lumbarpuncture_id", :name => "lumbarpuncture_result[lookup_lumbarpuncture_id]"
      assert_select "input#lumbarpuncture_result_value", :name => "lumbarpuncture_result[value]"
      assert_select "input#lumbarpuncture_result_value_string", :name => "lumbarpuncture_result[value_string]"
    end
  end
end
