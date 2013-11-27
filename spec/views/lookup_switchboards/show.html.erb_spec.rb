require 'spec_helper'

describe "lookup_switchboards/show.html.erb" do
  before(:each) do
    @lookup_switchboard = assign(:lookup_switchboard, stub_model(LookupSwitchboard,
      :description => "Description",
      :item_number => 1,
      :command => "Command",
      :argument => "Argument"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Command/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Argument/)
  end
end
