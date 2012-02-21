require 'spec_helper'

describe "lookup_scantasks/new.html.erb" do
  before(:each) do
    assign(:lookup_scantask, stub_model(LookupScantask,
      :description => "MyString",
      :name => "MyString",
      :pulse_sequence_code => "MyString",
      :bold_reps => "MyString",
      :task_code => 1,
      :set_id => 1
    ).as_new_record)
  end

  it "renders new lookup_scantask form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => lookup_scantasks_path, :method => "post" do
      assert_select "input#lookup_scantask_description", :name => "lookup_scantask[description]"
      assert_select "input#lookup_scantask_name", :name => "lookup_scantask[name]"
      assert_select "input#lookup_scantask_pulse_sequence_code", :name => "lookup_scantask[pulse_sequence_code]"
      assert_select "input#lookup_scantask_bold_reps", :name => "lookup_scantask[bold_reps]"
      assert_select "input#lookup_scantask_task_code", :name => "lookup_scantask[task_code]"
      assert_select "input#lookup_scantask_set_id", :name => "lookup_scantask[set_id]"
    end
  end
end
