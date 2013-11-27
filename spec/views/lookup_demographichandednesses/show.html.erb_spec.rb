require 'spec_helper'

describe "lookup_demographichandednesses/show.html.erb" do
  before(:each) do
    @lookup_demographichandedness = assign(:lookup_demographichandedness, stub_model(LookupDemographichandedness,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
