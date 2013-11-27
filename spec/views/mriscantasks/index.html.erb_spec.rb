require 'spec_helper'

describe "mriscantasks/index.html.erb" do
  before(:each) do
    assign(:mriscantasks, [
      stub_model(Mriscantask,
        :visit_id => 1,
        :lookup_set_id => 1,
        :lookup_scantask_id => 1,
        :preday => 1,
        :task_order => 1,
        :moved => 1,
        :eyecontact => 1,
        :logfilerecorded => 1,
        :p_file => "P File",
        :tasknote => "Tasknote",
        :reps => 1,
        :has_concerns => 1,
        :concerns => "Concerns"
      ),
      stub_model(Mriscantask,
        :visit_id => 1,
        :lookup_set_id => 1,
        :lookup_scantask_id => 1,
        :preday => 1,
        :task_order => 1,
        :moved => 1,
        :eyecontact => 1,
        :logfilerecorded => 1,
        :p_file => "P File",
        :tasknote => "Tasknote",
        :reps => 1,
        :has_concerns => 1,
        :concerns => "Concerns"
      )
    ])
  end

  it "renders a list of mriscantasks" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "P File".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Tasknote".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Concerns".to_s, :count => 2
  end
end
