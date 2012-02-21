require 'spec_helper'

describe "lookup_famhxes/show.html.erb" do
  before(:each) do
    @lookup_famhx = assign(:lookup_famhx, stub_model(LookupFamhx,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
