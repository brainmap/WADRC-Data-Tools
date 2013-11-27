require 'spec_helper'

describe "lookup_rads/show.html.erb" do
  before(:each) do
    @lookup_rad = assign(:lookup_rad, stub_model(LookupRad,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
