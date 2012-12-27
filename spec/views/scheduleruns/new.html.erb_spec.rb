require 'spec_helper'

describe "scheduleruns/new.html.erb" do
  before(:each) do
    assign(:schedulerun, stub_model(Schedulerun,
      :schedule_id => 1,
      :status_flag => "MyString",
      :log_file => "MyString"
    ).as_new_record)
  end

  it "renders new schedulerun form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => scheduleruns_path, :method => "post" do
      assert_select "input#schedulerun_schedule_id", :name => "schedulerun[schedule_id]"
      assert_select "input#schedulerun_status_flag", :name => "schedulerun[status_flag]"
      assert_select "input#schedulerun_log_file", :name => "schedulerun[log_file]"
    end
  end
end
