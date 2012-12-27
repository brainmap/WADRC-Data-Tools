require 'spec_helper'

describe "mriscantasks/show.html.erb" do
  before(:each) do
    @mriscantask = assign(:mriscantask, stub_model(Mriscantask,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/P File/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Tasknote/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Concerns/)
  end
end
