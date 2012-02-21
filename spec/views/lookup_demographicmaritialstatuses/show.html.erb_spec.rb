require 'spec_helper'

describe "lookup_demographicmaritialstatuses/show.html.erb" do
  before(:each) do
    @lookup_demographicmaritialstatus = assign(:lookup_demographicmaritialstatus, stub_model(LookupDemographicmaritialstatus,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
