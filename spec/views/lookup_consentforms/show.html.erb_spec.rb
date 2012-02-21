require 'spec_helper'

describe "lookup_consentforms/show.html.erb" do
  before(:each) do
    @lookup_consentform = assign(:lookup_consentform, stub_model(LookupConsentform,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
