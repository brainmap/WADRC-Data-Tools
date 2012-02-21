require 'spec_helper'

describe "lookup_cohorts/show.html.erb" do
  before(:each) do
    @lookup_cohort = assign(:lookup_cohort, stub_model(LookupCohort,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
