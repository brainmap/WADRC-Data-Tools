require 'spec_helper'

describe "lookup_relationships/show.html.erb" do
  before(:each) do
    @lookup_relationship = assign(:lookup_relationship, stub_model(LookupRelationship,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
