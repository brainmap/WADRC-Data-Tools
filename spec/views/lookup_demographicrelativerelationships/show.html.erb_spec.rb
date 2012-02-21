require 'spec_helper'

describe "lookup_demographicrelativerelationships/show.html.erb" do
  before(:each) do
    @lookup_demographicrelativerelationship = assign(:lookup_demographicrelativerelationship, stub_model(LookupDemographicrelativerelationship,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
