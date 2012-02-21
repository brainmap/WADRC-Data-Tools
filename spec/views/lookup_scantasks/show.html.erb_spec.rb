require 'spec_helper'

describe "lookup_scantasks/show.html.erb" do
  before(:each) do
    @lookup_scantask = assign(:lookup_scantask, stub_model(LookupScantask,
      :description => "Description",
      :name => "Name",
      :pulse_sequence_code => "Pulse Sequence Code",
      :bold_reps => "Bold Reps",
      :task_code => 1,
      :set_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Pulse Sequence Code/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Bold Reps/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
  end
end
