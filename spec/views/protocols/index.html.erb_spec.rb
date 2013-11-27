require 'spec_helper'

describe "protocols/index.html.erb" do
  before(:each) do
    assign(:protocols, [
      stub_model(Protocol,
        :name => "Name",
        :abbr => "Abbr",
        :path => "Path",
        :description => "Description"
      ),
      stub_model(Protocol,
        :name => "Name",
        :abbr => "Abbr",
        :path => "Path",
        :description => "Description"
      )
    ])
  end

  it "renders a list of protocols" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Abbr".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Path".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
