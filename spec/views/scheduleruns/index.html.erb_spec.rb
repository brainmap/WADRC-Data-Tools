require 'spec_helper'

describe "scheduleruns/index.html.erb" do
  before(:each) do
    assign(:scheduleruns, [
      stub_model(Schedulerun,
        :schedule_id => 1,
        :status_flag => "Status Flag",
        :log_file => "Log File"
      ),
      stub_model(Schedulerun,
        :schedule_id => 1,
        :status_flag => "Status Flag",
        :log_file => "Log File"
      )
    ])
  end

  it "renders a list of scheduleruns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Status Flag".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Log File".to_s, :count => 2
  end
end
