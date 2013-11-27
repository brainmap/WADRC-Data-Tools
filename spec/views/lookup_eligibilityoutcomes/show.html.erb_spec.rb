require 'spec_helper'

describe "lookup_eligibilityoutcomes/show.html.erb" do
  before(:each) do
    @lookup_eligibilityoutcome = assign(:lookup_eligibilityoutcome, stub_model(LookupEligibilityoutcome,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
