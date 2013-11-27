require 'spec_helper'

describe "lookup_bvmtpercentiles/show.html.erb" do
  before(:each) do
    @lookup_bvmtpercentile = assign(:lookup_bvmtpercentile, stub_model(LookupBvmtpercentile,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
