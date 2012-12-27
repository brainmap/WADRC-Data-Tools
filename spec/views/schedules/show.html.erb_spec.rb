require 'spec_helper'

describe "schedules/show.html.erb" do
  before(:each) do
    @schedule = assign(:schedule, stub_model(Schedule,
      :run_command => "Run Command",
      :parameters => "Parameters",
      :description => "Description",
      :run_time_length_min => 1,
      :status_flag => "Status Flag",
      :target_table => "Target Table",
      :target_column => "Target Column"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Run Command/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Parameters/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Status Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Target Table/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Target Column/)
  end
end
