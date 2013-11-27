require 'spec_helper'

describe "lookup_relationships/index.html.erb" do
  before(:each) do
    assign(:lookup_relationships, [
      stub_model(LookupRelationship,
        :description => "Description"
      ),
      stub_model(LookupRelationship,
        :description => "Description"
      )
    ])
  end

  it "renders a list of lookup_relationships" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Description".to_s, :count => 2
  end
end
