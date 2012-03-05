require 'spec_helper'

describe "lookup_refs/show.html.erb" do
  before(:each) do
    @lookup_ref = assign(:lookup_ref, stub_model(LookupRef,
      :ref_value => 1,
      :description => "Description",
      :display_order => 1,
      :label => "Label"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Label/)
  end
end
