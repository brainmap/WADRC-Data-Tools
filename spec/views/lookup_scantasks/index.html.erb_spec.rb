require 'spec_helper'

describe "lookup_scantasks/index.html.erb" do
  before(:each) do
    assign(:lookup_scantasks, [
      stub_model(LookupScantask,
        :description => "Description",
        :name => "Name",
        :pulse_sequence_code => "Pulse Sequence Code",
        :bold_reps => "Bold Reps",
        :task_code => 1,
        :set_id => 1
      ),
      stub_model(LookupScantask,
        :description => "Description",
        :name => "Name",
        :pulse_sequence_code => "Pulse Sequence Code",
        :bold_reps => "Bold Reps",
        :task_code => 1,
        :set_id => 1
      )
    ])
  end

  it "renders a list of lookup_scantasks" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Pulse Sequence Code".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Bold Reps".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
