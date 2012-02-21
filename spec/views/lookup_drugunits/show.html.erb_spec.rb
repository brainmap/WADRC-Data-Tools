require 'spec_helper'

describe "lookup_drugunits/show.html.erb" do
  before(:each) do
    @lookup_drugunit = assign(:lookup_drugunit, stub_model(LookupDrugunit,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
