require 'spec_helper'

describe "lookup_consentcohorts/show.html.erb" do
  before(:each) do
    @lookup_consentcohort = assign(:lookup_consentcohort, stub_model(LookupConsentcohort,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
