require 'spec_helper'

describe "lookup_drugfreqs/show.html.erb" do
  before(:each) do
    @lookup_drugfreq = assign(:lookup_drugfreq, stub_model(LookupDrugfreq,
      :frequency => "Frequency",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Frequency/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
