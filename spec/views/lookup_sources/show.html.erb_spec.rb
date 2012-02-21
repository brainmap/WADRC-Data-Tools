require 'spec_helper'

describe "lookup_sources/show.html.erb" do
  before(:each) do
    @lookup_source = assign(:lookup_source, stub_model(LookupSource,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
