require 'spec_helper'

describe "lookup_recruitsources/show.html.erb" do
  before(:each) do
    @lookup_recruitsource = assign(:lookup_recruitsource, stub_model(LookupRecruitsource,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
