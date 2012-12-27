require 'spec_helper'

describe "schedules/edit.html.erb" do
  before(:each) do
    @schedule = assign(:schedule, stub_model(Schedule,
      :run_command => "MyString",
      :parameters => "MyString",
      :description => "MyString",
      :run_time_length_min => 1,
      :status_flag => "MyString",
      :target_table => "MyString",
      :target_column => "MyString"
    ))
  end

  it "renders the edit schedule form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => schedule_path(@schedule), :method => "post" do
      assert_select "input#schedule_run_command", :name => "schedule[run_command]"
      assert_select "input#schedule_parameters", :name => "schedule[parameters]"
      assert_select "input#schedule_description", :name => "schedule[description]"
      assert_select "input#schedule_run_time_length_min", :name => "schedule[run_time_length_min]"
      assert_select "input#schedule_status_flag", :name => "schedule[status_flag]"
      assert_select "input#schedule_target_table", :name => "schedule[target_table]"
      assert_select "input#schedule_target_column", :name => "schedule[target_column]"
    end
  end
end
