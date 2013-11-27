require 'spec_helper'

describe "lookup_lumbarpunctures/show.html.erb" do
  before(:each) do
    @lookup_lumbarpuncture = assign(:lookup_lumbarpuncture, stub_model(LookupLumbarpuncture,
      :description => "Description",
      :units => "Units",
      :range => "Range"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Units/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Range/)
  end
end
