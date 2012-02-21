require 'spec_helper'

describe "protocols/show.html.erb" do
  before(:each) do
    @protocol = assign(:protocol, stub_model(Protocol,
      :name => "Name",
      :abbr => "Abbr",
      :path => "Path",
      :description => "Description"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Abbr/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Path/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Description/)
  end
end
