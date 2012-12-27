require 'spec_helper'

describe "schedules/index.html.erb" do
  before(:each) do
    assign(:schedules, [
      stub_model(Schedule,
        :run_command => "Run Command",
        :parameters => "Parameters",
        :description => "Description",
        :run_time_length_min => 1,
        :status_flag => "Status Flag",
        :target_table => "Target Table",
        :target_column => "Target Column"
      ),
      stub_model(Schedule,
        :run_command => "Run Command",
        :parameters => "Parameters",
        :description => "Description",
        :run_time_length_min => 1,
        :status_flag => "Status Flag",
        :target_table => "Target Table",
        :target_column => "Target Column"
      )
    ])
  end

  it "renders a list of schedules" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Run Command".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Parameters".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Status Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Target Table".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Target Column".to_s, :count => 2
  end
end
