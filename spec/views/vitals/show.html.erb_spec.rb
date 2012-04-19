require 'spec_helper'

describe "vitals/show.html.erb" do
  before(:each) do
    @vital = assign(:vital, stub_model(Vital,
      :appointment_id => 1,
      :bp_systol => 1,
      :bp_diastol => 1,
      :pulse => 1,
      :bloodglucose => 1
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
  end
end
