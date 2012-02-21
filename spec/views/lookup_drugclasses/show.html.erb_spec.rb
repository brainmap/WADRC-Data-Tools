require 'spec_helper'

describe "lookup_drugclasses/show.html.erb" do
  before(:each) do
    @lookup_drugclass = assign(:lookup_drugclass, stub_model(LookupDrugclass,
      :epodrugclass => "Epodrugclass",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Epodrugclass/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
