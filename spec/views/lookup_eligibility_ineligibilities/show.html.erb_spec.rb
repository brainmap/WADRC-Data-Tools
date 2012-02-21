require 'spec_helper'

describe "lookup_eligibility_ineligibilities/show.html.erb" do
  before(:each) do
    @lookup_eligibility_ineligibility = assign(:lookup_eligibility_ineligibility, stub_model(LookupEligibilityIneligibility,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
