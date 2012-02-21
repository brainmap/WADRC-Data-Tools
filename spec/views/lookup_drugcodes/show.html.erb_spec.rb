require 'spec_helper'

describe "lookup_drugcodes/show.html.erb" do
  before(:each) do
    @lookup_drugcode = assign(:lookup_drugcode, stub_model(LookupDrugcode,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
