require 'spec_helper'

describe "lookup_truthtables/show.html.erb" do
  before(:each) do
    @lookup_truthtable = assign(:lookup_truthtable, stub_model(LookupTruthtable,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
