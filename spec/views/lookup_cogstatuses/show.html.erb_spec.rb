require 'spec_helper'

describe "lookup_cogstatuses/show.html.erb" do
  before(:each) do
    @lookup_cogstatus = assign(:lookup_cogstatus, stub_model(LookupCogstatus,
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
