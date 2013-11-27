require 'spec_helper'

describe "vitals/index.html.erb" do
  before(:each) do
    assign(:vitals, [
      stub_model(Vital,
        :appointment_id => 1,
        :bp_systol => 1,
        :bp_diastol => 1,
        :pulse => 1,
        :bloodglucose => 1
      ),
      stub_model(Vital,
        :appointment_id => 1,
        :bp_systol => 1,
        :bp_diastol => 1,
        :pulse => 1,
        :bloodglucose => 1
      )
    ])
  end

  it "renders a list of vitals" do
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
  end
end
