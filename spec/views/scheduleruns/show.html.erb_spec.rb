require 'spec_helper'

describe "scheduleruns/show.html.erb" do
  before(:each) do
    @schedulerun = assign(:schedulerun, stub_model(Schedulerun,
      :schedule_id => 1,
      :status_flag => "Status Flag",
      :log_file => "Log File"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Status Flag/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Log File/)
  end
end
