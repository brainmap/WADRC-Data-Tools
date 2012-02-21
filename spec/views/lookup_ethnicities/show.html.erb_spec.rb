require 'spec_helper'

describe "lookup_ethnicities/show.html.erb" do
  before(:each) do
    @lookup_ethnicity = assign(:lookup_ethnicity, stub_model(LookupEthnicity,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
