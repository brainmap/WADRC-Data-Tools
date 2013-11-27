require 'spec_helper'

describe "lookup_sets/show.html.erb" do
  before(:each) do
    @lookup_set = assign(:lookup_set, stub_model(LookupSet,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
