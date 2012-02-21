require 'spec_helper'

describe "lookup_demographicmaritalstatuses/show.html.erb" do
  before(:each) do
    @lookup_demographicmaritalstatus = assign(:lookup_demographicmaritalstatus, stub_model(LookupDemographicmaritalstatus,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
