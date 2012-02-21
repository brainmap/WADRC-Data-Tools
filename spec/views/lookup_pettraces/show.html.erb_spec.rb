require 'spec_helper'

describe "lookup_pettraces/show.html.erb" do
  before(:each) do
    @lookup_pettrace = assign(:lookup_pettrace, stub_model(LookupPettrace,
      :name => "Name",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
