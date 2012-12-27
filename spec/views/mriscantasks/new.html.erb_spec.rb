require 'spec_helper'

describe "mriscantasks/new.html.erb" do
  before(:each) do
    assign(:mriscantask, stub_model(Mriscantask,
      :visit_id => 1,
      :lookup_set_id => 1,
      :lookup_scantask_id => 1,
      :preday => 1,
      :task_order => 1,
      :moved => 1,
      :eyecontact => 1,
      :logfilerecorded => 1,
      :p_file => "MyString",
      :tasknote => "MyString",
      :reps => 1,
      :has_concerns => 1,
      :concerns => "MyString"
    ).as_new_record)
  end

  it "renders new mriscantask form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => mriscantasks_path, :method => "post" do
      assert_select "input#mriscantask_visit_id", :name => "mriscantask[visit_id]"
      assert_select "input#mriscantask_lookup_set_id", :name => "mriscantask[lookup_set_id]"
      assert_select "input#mriscantask_lookup_scantask_id", :name => "mriscantask[lookup_scantask_id]"
      assert_select "input#mriscantask_preday", :name => "mriscantask[preday]"
      assert_select "input#mriscantask_task_order", :name => "mriscantask[task_order]"
      assert_select "input#mriscantask_moved", :name => "mriscantask[moved]"
      assert_select "input#mriscantask_eyecontact", :name => "mriscantask[eyecontact]"
      assert_select "input#mriscantask_logfilerecorded", :name => "mriscantask[logfilerecorded]"
      assert_select "input#mriscantask_p_file", :name => "mriscantask[p_file]"
      assert_select "input#mriscantask_tasknote", :name => "mriscantask[tasknote]"
      assert_select "input#mriscantask_reps", :name => "mriscantask[reps]"
      assert_select "input#mriscantask_has_concerns", :name => "mriscantask[has_concerns]"
      assert_select "input#mriscantask_concerns", :name => "mriscantask[concerns]"
    end
  end
end
